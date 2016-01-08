//
//  WebServices.m
//  Konotor
//
//  Created by Vignesh G on 12/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import "WebServices.h"
#import "AFNetworking.h"
#import "KonotorUtil.h"
#import "KonotorMessage.h"
#import "KonotorMessageBinary.h"
#import "KonotorUtil.h"
#import "Konotor.h"
#import "HLMacros.h"
#import "FDUtilities.h"
#import "FDSecureStore.h"

@implementation KonotorWebServices

//TODO: Move this to HLMessageService
+(void) uploadMessage:(KonotorMessage *)pMessage toConversation:(KonotorConversation *)conversation onChannel:(HLChannel *)channel{
    if(![pMessage isMarkedForUpload]){
        pMessage.isMarkedForUpload = YES;
        [[KonotorDataManager sharedInstance]save];
    }

    UIBackgroundTaskIdentifier bgtask = [KonotorUtil beginBackgroundExecutionWithExpirationHandler:@selector(HandleMessageUploadExpiry:) withParameters:nil forObject:[KonotorWebServices class]];
    
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
   
    NSURL *url = [NSURL URLWithString:[KonotorUtil GetBaseURL]];
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
    
    [KonotorNetworkUtil SetNetworkActivityIndicator:YES];
    
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

        [KonotorNetworkUtil SetNetworkActivityIndicator:NO];
        pMessage.uploadStatus = @(MESSAGE_UPLOADED);
        pMessage.messageAlias = messageInfo[@"alias"];
        [channel addMessagesObject:pMessage];
        [[KonotorDataManager sharedInstance]save];
        [KonotorUtil EndBackgroundExecutionForTask:bgtask];
        [Konotor performSelector:@selector(UploadFinishedNotifcation:) withObject:messageAlias];
     }
     
    failure:^(AFKonotorHTTPRequestOperation *operation, NSError *error){
        [KonotorNetworkUtil SetNetworkActivityIndicator:NO];
        pMessage.messageAlias = [FDUtilities generateOfflineMessageAlias];
        pMessage.uploadStatus = @(MESSAGE_NOT_UPLOADED);
        [channel addMessagesObject:pMessage];
        [[KonotorDataManager sharedInstance]save];
        [Konotor performSelector:@selector(UploadFailedNotifcation:) withObject:messageAlias];
        [KonotorUtil EndBackgroundExecutionForTask:bgtask];
     }];
    
    [operation start];
}

@end