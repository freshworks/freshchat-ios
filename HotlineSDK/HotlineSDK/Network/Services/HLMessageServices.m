//
//  HLMessageServices.m
//  HotlineSDK
//
//  Created by user on 03/11/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "HLMessageServices.h"
#import "HLAPIClient.h"
#import "HLServiceRequest.h"
#import "HLMacros.h"
#import "FDSecureStore.h"
#import "KonotorDataManager.h"
#import "HLAPI.h"
#import "FDLocalNotification.h"
#import "KonotorConversation.h"
#import "FDUtilities.h"
#import "Konotor.h"
#import "KonotorMessage.h"
#import "AFHTTPClient.h"
#import "AFNetworking.h"
#import "FDResponseInfo.h"

static BOOL MESSAGES_DOWNLOAD_IN_PROGRESS = NO;

@implementation HLMessageServices

+(void)downloadAllMessages:(void(^)(NSError *error))handler{
    FDLog(@"download message called");
    
    if (MESSAGES_DOWNLOAD_IN_PROGRESS) {
        FDLog(@"download message in progress, so skip");
        return;
    }
    
    MESSAGES_DOWNLOAD_IN_PROGRESS = YES;
    
    ShowNetworkActivityIndicator();
    HLMessageServices *messageService = [[HLMessageServices alloc]init];
    [messageService fetchAllChannels:^(NSArray<HLChannel *> *channels, NSError *error) {
        if (!error) {
            [self fetchAllMessagesInChannel:channels handler:handler];
        }else{
            if(handler) handler(error);
            MESSAGES_DOWNLOAD_IN_PROGRESS = NO;
        }
    }];
}

+(void)fetchAllMessagesInChannel:(NSArray *)channels handler:(void(^)(NSError *error))handler{
    NSString *pBasePath = [FDUtilities getBaseURL];
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FDUtilities getUserAlias];
    NSString *appKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];
    NSNumber *lastUpdateTime = [store objectForKey:HOTLINE_DEFAULTS_CHANNELS_LAST_UPDATED_TIME];
    
    if (lastUpdateTime == nil) {
        lastUpdateTime = @0;
        FDLog(@"Restoring user messages with alias :%@", userAlias);
    }
    
    NSString *getPath = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@",pBasePath,@"services/app/",appID,@"/user/",userAlias,@"/conversation/v2?t=",appKey,@"&messageAfter=",lastUpdateTime];
    
    AFKonotorHTTPClient *httpClient = [[AFKonotorHTTPClient alloc]initWithBaseURL:[NSURL URLWithString:pBasePath]];
    [httpClient setDefaultHeader:@"Accept" value:@"application/json"];
    [httpClient setDefaultHeader:@"Content-Type" value:@"application/json"];
    [httpClient setParameterEncoding:AFKonotorJSONParameterEncoding];
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET" path:getPath parameters:nil];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        int statusCode = (int)[httpResponse statusCode];
        
        FDLog(@"Download all message call status :%d", statusCode);
        
        if(error || statusCode >= 400){
            FDLog(@"Message fetch failed %@", error);
            HideNetworkActivityIndicator();
            MESSAGES_DOWNLOAD_IN_PROGRESS = NO;
            [Konotor performSelector:@selector(conversationsDownloadFailed)];
            if(handler) handler(error);
            return;
            
        }else{
            
            HideNetworkActivityIndicator();
            id JSON  = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:&error];
            NSDictionary *toplevel = [NSDictionary dictionaryWithDictionary:JSON];
            
            FDLog(@"Messages :%@", toplevel);
            
            if(!toplevel){
                MESSAGES_DOWNLOAD_IN_PROGRESS = NO;
                [Konotor performSelector:@selector(conversationsDownloaded)];
                return;
            }
            
            NSMutableArray *pArrayOfConversations = [NSMutableArray arrayWithArray:[toplevel valueForKey:@"conversations"]];
            
            if(!pArrayOfConversations){
                MESSAGES_DOWNLOAD_IN_PROGRESS = NO;
                [Konotor performSelector:@selector(conversationsDownloaded)];
                return;
            }
            
            for (int i=0; i<pArrayOfConversations.count; i++) {
                NSDictionary *conversationInfo = pArrayOfConversations[i];
                NSNumber *channelId = conversationInfo[@"channelId"];
                HLChannel *channel = [HLChannel getWithID:channelId  inContext:[KonotorDataManager sharedInstance].mainObjectContext];
                NSString *conversationID = [conversationInfo[@"conversationId"] stringValue];
                KonotorConversation *conversation = [KonotorConversation RetriveConversationForConversationId:conversationID];
                NSArray *messages = conversationInfo[@"messages"];
                for (int j=0; j<messages.count; j++) {
                    NSDictionary *messageInfo = messages[j];
                    KonotorMessage *message = [KonotorMessage retriveMessageForMessageId:messageInfo[@"alias"]];
                    if (!message) {
                        KonotorMessage *newMessage = [KonotorMessage createNewMessage:messageInfo];
                        newMessage.uploadStatus = @2;
                        
                        if (channel) {
                            newMessage.belongsToChannel = channel;
                        }
                        
                        if (!conversation) {
                            conversation = [KonotorConversation createConversationWithID:conversationID ForChannel:channel];
                        }
                        
                        newMessage.belongsToConversation = conversation;
                    }
                }
            }
            if(handler) handler(nil);
            [Konotor performSelector:@selector(conversationsDownloaded)];
        }
        NSNumber *lastUpdatedTime = [NSNumber numberWithDouble:round([[NSDate date] timeIntervalSince1970]*1000)];
        [[FDSecureStore sharedInstance] setObject:lastUpdatedTime forKey:HOTLINE_DEFAULTS_CHANNELS_LAST_UPDATED_TIME];
        [[KonotorDataManager sharedInstance]save];
        MESSAGES_DOWNLOAD_IN_PROGRESS = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:HOTLINE_MESSAGES_DOWNLOADED object:self];
    }];
}

-(NSURLSessionDataTask *)fetchAllChannels:(void (^)(NSArray<HLChannel *> *channels, NSError *error))handler{
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    FDSecureStore *store = [FDSecureStore sharedInstance];
    //TODO: This is repeated multitimes. Needs refactor.
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:HOTLINE_USER_DOMAIN,[store objectForKey:HOTLINE_DEFAULTS_DOMAIN]]]];
    request.HTTPMethod = HTTP_METHOD_GET;
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *appKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_CHANNELS_PATH,appID];
    NSString *token = [NSString stringWithFormat:HOTLINE_REQUEST_PARAMS,appKey];
    [request setRelativePath:path andURLParams:@[token]];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
        if (!error) {
            [self importChannels:[responseInfo responseAsArray] handler:handler];
        }else{
            if (handler) handler(nil, error);
            FDLog(@"channel fetch failed :%@ \n response : %@",error, responseInfo.response);
        }
    }];
    return task;
}

-(void)importChannels:(NSArray *)channels handler:(void (^)(NSArray *channels, NSError *error))handler;{
    NSMutableArray *channelList = [NSMutableArray new];
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].mainObjectContext;
    [context performBlock:^{
        NSInteger channelCount = [channels count];
        HLChannel *channel = nil;
        if (channelCount!=0) {
            for(int i=0; i<channels.count; i++){
                NSDictionary *channelInfo = channels[i];
                channel = [HLChannel getWithID:channelInfo[@"channelId"] inContext:context];
                if (channel) {
                    NSDate *updateTime = [NSDate dateWithTimeIntervalSince1970:[channelInfo[@"updated"]doubleValue]];
                    if ([channel.lastUpdated compare:updateTime] == NSOrderedAscending) {
                        [HLChannel updateChannel:channel withInfo:channelInfo];
                        FDLog(@"Channel with ID:%@ updated", channel.channelID);
                    }
                }else{
                    channel = [HLChannel createWithInfo:channelInfo inContext:context];
                }
                [channelList addObject:channel];
            }
        }
        [context save:nil];
        if (handler) handler(channelList,nil);
        [self postNotification];
    }];
}

-(void)postNotification{
    [[NSNotificationCenter defaultCenter] postNotificationName:HOTLINE_CHANNELS_UPDATED object:self];
}

+(void)uploadMessage:(KonotorMessage *)pMessage toConversation:(KonotorConversation *)conversation onChannel:(HLChannel *)channel{
    if(![pMessage isMarkedForUpload]){
        pMessage.isMarkedForUpload = YES;
        [[KonotorDataManager sharedInstance]save];
    }
    
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FDUtilities getUserAlias];
    NSString *appKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];
    
    __block NSString *messageAlias = pMessage.messageAlias;
    
    if([[pMessage uploadStatus]intValue] == MESSAGE_UPLOADED || [[pMessage uploadStatus]intValue] == MESSAGE_UPLOADING){
        return;
    }else{
        pMessage.uploadStatus = @(MESSAGE_UPLOADING);
        [[KonotorDataManager sharedInstance]save];
    }
    
    NSURL *url = [NSURL URLWithString:[FDUtilities getBaseURL]];
    AFKonotorHTTPClient *httpClient = [[AFKonotorHTTPClient alloc] initWithBaseURL:url];
    
    NSString *postPath = [NSString stringWithFormat:@"%@%@%@%@%@%@",@"services/app/",appID,@"/user/",userAlias,@"/feedback/message/v2?t=",appKey];
    
    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:postPath parameters:nil constructingBodyWithBlock: ^(id <AFKonotorMultipartFormData>formData) {
        
        [formData appendPartWithFormData:[[pMessage getJSON] dataUsingEncoding:NSUTF8StringEncoding] name:@"message"];
        
        if (channel.channelID) {
            [formData appendPartWithFormData:[channel.channelID.stringValue dataUsingEncoding:NSUTF8StringEncoding]
                                        name:@"channelId"];
        }else{
            FDLog(@"Message sending without channel ID");
        }
        
        
        if (conversation.conversationAlias) {
            [formData appendPartWithFormData:[conversation.conversationAlias dataUsingEncoding:NSUTF8StringEncoding] name:@"conversationId"];
        }else{
            FDLog(@"Message sending without conversation ID");
        }
        
        //if audio message add the binary audio also.
        if([[pMessage messageType]intValue]== 2){
            KonotorMessageBinary *pBinary = (KonotorMessageBinary*)[pMessage valueForKeyPath:@"hasMessageBinary"];
            
            if(pBinary){
                [formData appendPartWithFileData:[pBinary binaryAudio] name:@"file" fileName:@"file2" mimeType:@"application/octet-stream"];
            }
        }
        
        //if audio message add the binary audio also.
        if([[pMessage messageType]intValue]== 3) {
            KonotorMessageBinary *pBinary = (KonotorMessageBinary*)[pMessage valueForKeyPath:@"hasMessageBinary"];
            
            if(pBinary){
                [formData appendPartWithFileData:[pBinary binaryImage] name:@"picFile" fileName:@".jpg"
                                        mimeType:@"application/octet-stream"];
                
                if([pBinary binaryThumbnail]){
                    [formData appendPartWithFileData:[pBinary binaryThumbnail] name:@"picThumbFile" fileName:@".jpg"
                                            mimeType:@"application/octet-stream"];
                }
            }
        }
    }];
    
    ShowNetworkActivityIndicator();
    
    AFKonotorHTTPRequestOperation *operation = [[AFKonotorHTTPRequestOperation alloc] initWithRequest:request];
    
    [operation setCompletionBlockWithSuccess:^(AFKonotorHTTPRequestOperation *operation, id responseObject){
        
        NSDictionary* messageInfo = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:nil];
        
        if (!conversation) {
            NSString *conversationID = [messageInfo[@"hostConversationId"] stringValue];
            KonotorConversation *newConversation = [KonotorConversation createConversationWithID:conversationID ForChannel:channel];
            pMessage.belongsToConversation = newConversation;
        }else{
            pMessage.belongsToConversation = conversation;
        }
        
        HideNetworkActivityIndicator();
        pMessage.uploadStatus = @(MESSAGE_UPLOADED);
        pMessage.messageAlias = messageInfo[@"alias"];
        pMessage.createdMillis = messageInfo[@"createdMillis"];
        [channel addMessagesObject:pMessage];
        [[KonotorDataManager sharedInstance]save];
        [Konotor performSelector:@selector(UploadFinishedNotifcation:) withObject:messageAlias];
    }
     
                                     failure:^(AFKonotorHTTPRequestOperation *operation, NSError *error){
                                         HideNetworkActivityIndicator();
                                         pMessage.messageAlias = [FDUtilities generateOfflineMessageAlias];
                                         pMessage.uploadStatus = @(MESSAGE_NOT_UPLOADED);
                                         [channel addMessagesObject:pMessage];
                                         [[KonotorDataManager sharedInstance]save];
                                         [Konotor performSelector:@selector(UploadFailedNotifcation:) withObject:messageAlias];
                                     }];
    
    [operation start];
}


//TODO: Skip messages that are 'click registered' already & use HLAPIClient
+(void)markMarketingMessageAsClicked:(NSNumber *)marketingId{
    NSURL *url = [NSURL URLWithString:[FDUtilities getBaseURL]];
    AFKonotorHTTPClient *httpClient = [[AFKonotorHTTPClient alloc] initWithBaseURL:url];
    [httpClient setDefaultHeader:@"Content-Type" value:@"application/json"];
    
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FDUtilities getUserAlias];
    NSString *appKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];
    
    if([marketingId intValue] ==0 || !marketingId) return;
    
    //PUT {appId}/user/{alias}/message/marketing/{marketingId}/status?delivered=1&clicked=1&seen=1&t={appkey}
    NSString *postPath = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@",@"services/app/",appID,@"/user/",userAlias,@"/message/marketing/",[marketingId stringValue ],@"/status?clicked=1&t=",appKey];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"PUT" path:postPath parameters:nil];
    AFKonotorHTTPRequestOperation *operation = [[AFKonotorHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFKonotorHTTPRequestOperation *operation, id responseObject) {
        FDLog(@"Marketing message with ID %@ click event pushed to server", marketingId);
    } failure:^(AFKonotorHTTPRequestOperation *operation, NSError *error) {
        FDLog(@"Failed to register marketing message click event to server");
    }];
    [operation start];
}


//TODO: Use HLAPIClient
+(void)markMarketingMessageAsRead:(KonotorMessage *)message{
    if (message.messageRead == YES) return;
    
    NSNumber *marketingId = message.marketingId;
    
    if([marketingId intValue] ==0 || !marketingId) return;
    
    message.messageRead = YES;
    
    NSURL *url = [NSURL URLWithString:[FDUtilities getBaseURL]];
    AFKonotorHTTPClient *httpClient = [[AFKonotorHTTPClient alloc] initWithBaseURL:url];
    [httpClient setDefaultHeader:@"Content-Type" value:@"application/json"];
    
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FDUtilities getUserAlias];
    NSString *appKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];
    
    NSString *postPath = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@",@"services/app/",appID,@"/user/",userAlias,@"/message/marketing/",[marketingId stringValue ],@"/status?seen=1&t=",appKey];
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"PUT" path:postPath parameters:nil];
    AFKonotorHTTPRequestOperation *operation = [[AFKonotorHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFKonotorHTTPRequestOperation *operation, id responseObject) {
        FDLog(@"Marked marketing msg with ID : %@ as read", marketingId);
    } failure:^(AFKonotorHTTPRequestOperation *operation, NSError *error) {
        [message markAsUnread];
    }];
    [operation start];
}


@end