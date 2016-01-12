//
//  KonotorConversation.m
//  Konotor
//
//  Created by Vignesh G on 15/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import "KonotorConversation.h"
#import "KonotorDataManager.h"
#import "KonotorUtil.h"
#import "KonotorMessage.h"
#import "Konotor.h"
#import "HLMessageServices.h"
#import "HLMacros.h"
#import "FDSecureStore.h"
#import "FDUtilities.h"

@class KonotorConversationData;
@class KonotorMessageData;

@implementation KonotorConversation

@dynamic conversationAlias;
@dynamic conversationHostUserAlias;
@dynamic conversationHostUserId;
@dynamic createdMillis;
@dynamic status;
@dynamic unreadMessagesCount;
@dynamic updatedMillis;
@dynamic belongsToChannel;
@dynamic hasMessages;

static BOOL DOWNLOAD_IN_PROGRESS = NO;

NSMutableDictionary* gkConversationIdConversationMap;

-(void)incrementUnreadCount{
    int unread = self.unreadMessagesCount.intValue;
    unread++;
    self.unreadMessagesCount = @(unread);
    [KonotorUtil PostNotificationWithName:@"KonotorUnreadMessagesCount" withObject:[NSNumber numberWithInt:unread]];
    [[KonotorDataManager sharedInstance]save];
}

-(void)decrementUnreadCount{
    int unread = [[self unreadMessagesCount]intValue];
    if(unread > 0){
        unread--;
    }
    [self setUnreadMessagesCount:[NSNumber numberWithInt:unread]];
    [KonotorUtil PostNotificationWithName:@"KonotorUnreadMessagesCount" withObject:[NSNumber numberWithInt:unread]];
    [[KonotorDataManager sharedInstance]save];
}

+(KonotorConversation *) RetriveConversationForConversationId: (NSString *)conversationId
{
    if(gkConversationIdConversationMap)
    {
        KonotorConversation *conversation = [gkConversationIdConversationMap objectForKey:conversationId];
        if(conversation)
            return conversation;
    }
    
    if(!gkConversationIdConversationMap)
    {
        gkConversationIdConversationMap = [[ NSMutableDictionary alloc]init];
    }
    
    NSError *pError;
    NSManagedObjectContext *context = [[KonotorDataManager sharedInstance]mainObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"KonotorConversation" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    [request setEntity:entityDescription];
    
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"conversationAlias == %@",conversationId];
    
    [request setPredicate:predicate];
    
    NSArray *array = [context executeFetchRequest:request error:&pError];
    
    if([array count]==0) return nil;
    
    if([array count] >1)
        NSLog(@"%@", @"Multiple Messages stored with the same message Id");
    
    else if([array count]==1)
    {
        KonotorConversation *conversation = [array objectAtIndex:0];
        if(conversation)
        {
            [gkConversationIdConversationMap setObject:conversation forKey:conversationId];
            return conversation;
        }
    }
    return nil;
}

+(void) DownloadAllMessages{
    FDLog(@"download message called");
    
    if (DOWNLOAD_IN_PROGRESS) {
        FDLog(@"download message in progress, so skip");
        return;
    }

    [KonotorNetworkUtil SetNetworkActivityIndicator:YES];
    HLMessageServices *messageService = [[HLMessageServices alloc]init];
    [messageService fetchAllChannels:^(NSArray<HLChannel *> *channels, NSError *error) {
        [KonotorConversation fetchAllMessagesInChannel:channels];
    }];
}

//TODO: Move this to HLMessageServices

+ (void)fetchAllMessagesInChannel:(NSArray *)channels{

    NSString *pBasePath = [KonotorUtil GetBaseURL];

    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FDUtilities getUserAlias];
    NSString *appKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];
    
    //TODO: set channel last updated time to get delta updates
    NSNumber *lastUpdateTime = [store objectForKey:HOTLINE_DEFAULTS_CHANNELS_LAST_UPDATED_TIME];
    
    if (lastUpdateTime == nil) {
        lastUpdateTime = @0;
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
        
        FDLog(@"Path %@", response.URL);
        
        FDLog(@"Download all message call status :%d", statusCode);
        
        if(error || statusCode >= 400){
            [KonotorNetworkUtil SetNetworkActivityIndicator:NO];
            [Konotor performSelector:@selector(conversationsDownloadFailed)];
            return;
            
        }else{
            
            [KonotorNetworkUtil SetNetworkActivityIndicator:NO];
            id JSON  = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:&error];
            NSDictionary *toplevel = [NSDictionary dictionaryWithDictionary:JSON];
            
            FDLog(@"Messages :%@", toplevel);
            
            if(!toplevel){
                [Konotor performSelector:@selector(conversationsDownloaded)];
                return;
            }
            
            NSMutableArray *pArrayOfConversations = [NSMutableArray arrayWithArray:[toplevel valueForKey:@"conversations"]];
            
            if(!pArrayOfConversations){
                [Konotor performSelector:@selector(conversationsDownloaded)];
                return;
            }
            
            DOWNLOAD_IN_PROGRESS = YES;
            
            for (int i=0; i<pArrayOfConversations.count; i++) {
                NSDictionary *conversationInfo = pArrayOfConversations[i];
                NSString *conversationID = [conversationInfo[@"conversationId"] stringValue];
                KonotorConversation *conversation = [KonotorConversation RetriveConversationForConversationId:conversationID];
                if (conversation) {
                    NSArray *messages = conversationInfo[@"messages"];
                    for (int j=0; j<messages.count; j++) {
                        NSDictionary *messageInfo = messages[j];
                        KonotorMessage *message = [KonotorMessage retriveMessageForMessageId:messageInfo[@"alias"]];
                        if (!message) {
                            KonotorMessage *newMessage = [KonotorMessage createNewMessage:messageInfo];
                            newMessage.uploadStatus = @2;
                            newMessage.belongsToConversation = conversation;
                            [conversation.belongsToChannel addMessagesObject:newMessage];
                            [conversation incrementUnreadCount];
                        }
                    }
                }else{
                    NSNumber *channelId = conversationInfo[@"channelId"];
                    HLChannel *channel = [HLChannel getWithID:channelId  inContext:[KonotorDataManager sharedInstance].mainObjectContext];
                    KonotorConversation *newConversation = [KonotorConversation createConversationWithID:conversationID ForChannel:channel];
                    NSArray *messages = conversationInfo[@"messages"];
                    for (int j=0; j<messages.count; j++) {
                        NSDictionary *messageInfo = messages[j];
                        KonotorMessage *newMessage = [KonotorMessage createNewMessage:messageInfo];
                        newMessage.uploadStatus = @2;
                        newMessage.belongsToConversation = newConversation;
                        [newConversation.belongsToChannel addMessagesObject:newMessage];
                        [channel addMessagesObject:newMessage];
                        [newConversation incrementUnreadCount];
                    }
                }
            }
            [Konotor performSelector:@selector(conversationsDownloaded)];
        }
        NSNumber *lastUpdatedTime = [NSNumber numberWithDouble:round([[NSDate date] timeIntervalSince1970]*1000)];
        [[FDSecureStore sharedInstance] setObject:lastUpdatedTime forKey:HOTLINE_DEFAULTS_CHANNELS_LAST_UPDATED_TIME];
        [[KonotorDataManager sharedInstance]save];
        DOWNLOAD_IN_PROGRESS = NO;
    }];
}

-(KonotorConversationData *) ReturnConversationDataFromManagedObject
{
    KonotorConversationData *conversation = [[KonotorConversationData alloc]init];
    conversation.conversationAlias = [self conversationAlias];
    conversation.lastUpdated = [self updatedMillis];
    conversation.unreadMessagesCount = [self unreadMessagesCount];
    return conversation;
    
}

+(KonotorConversation *)createConversationWithID:(NSString *)conversationID ForChannel:(HLChannel *)channel{
    NSManagedObjectContext *context = [[KonotorDataManager sharedInstance]mainObjectContext];
    KonotorConversation *newConversation = [NSEntityDescription insertNewObjectForEntityForName:@"KonotorConversation" inManagedObjectContext:context];

    newConversation.conversationAlias = conversationID;

    if (channel) {
        newConversation.belongsToChannel = channel;
    }
    
    return newConversation;
}

@end