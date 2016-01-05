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
#import "KonotorCustomProperties.h"
#import "KonotorShareMessageEvent.h"
#import "HLMacros.h"
#import "FDUtilities.h"
#import "FDSecureStore.h"

@implementation KonotorWebServices

+(void) HandlePropertyUploadExpiry:(id)parameter{
    KonotorCustomProperty *prop = (KonotorCustomProperty *)parameter;
    [prop setUploadStatus:[NSNumber numberWithInt:PROPERTY_NOT_UPLOADED]];
}

+(void) UpdateAppVersion:(NSString *) appVersion{
    //TODO: Set app version in secure store
    //[KonotorUser setCustomUserProperty:appVersion forKey:@"app_version"];
}

//TODO: Move this to HLCoreServices
+(void) UpdateSdkVersion: (NSString *) sdkVersion{
    
    NSString *pBasePath = [KonotorUtil GetBaseURL];
    AFKonotorHTTPClient *httpClient = [[AFKonotorHTTPClient alloc]initWithBaseURL:[NSURL URLWithString:pBasePath]];
    [httpClient setDefaultHeader:@"Content-Type" value:@"application/x-www-form-urlencoded"];
    [httpClient setParameterEncoding:AFKonotorJSONParameterEncoding];
    NSMutableDictionary *topLevel=[[NSMutableDictionary alloc]init];

    NSData *pEncodedJSON;
    NSError *pError;
    pEncodedJSON = [NSJSONSerialization dataWithJSONObject:topLevel  options:NSJSONWritingPrettyPrinted error:&pError];
    
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FDUtilities getUserAlias];
    NSString *appKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];

    NSString *path = [NSString stringWithFormat:@"services/app/%@/user/%@/client?t=%@&clientVersion=%@&clientType=2", appID, userAlias, appKey, sdkVersion];
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"PUT" path:path parameters:nil];
    [KonotorNetworkUtil SetNetworkActivityIndicator:YES];
    
    AFKonotorHTTPRequestOperation *operation = [[AFKonotorHTTPRequestOperation alloc] initWithRequest:request];
    
    [operation setCompletionBlockWithSuccess:^(AFKonotorHTTPRequestOperation *operation, id JSON){
        
        //TODO: update latest SDK version in secure store

        //[KonotorApp UpdateSDKVersion:sdkVersion];
         [[KonotorDataManager sharedInstance]save];
         [KonotorNetworkUtil SetNetworkActivityIndicator:NO];
     }
     
    failure:^(AFKonotorHTTPRequestOperation *operation, NSError *error){
         [KonotorNetworkUtil SetNetworkActivityIndicator:NO];
     }];
    [operation start];
}


//TODO: Move this to HLCoreServices
+(void) sendShareMessageEvent:(KonotorShareMessageEvent *)shareEvent{
 
    //TODO: check if uploadAllUnuploaded events is needed here
    
    NSUInteger bgtask = [KonotorUtil beginBackgroundExecutionWithExpirationHandler:@selector(HandleUserCreateExpiry:) withParameters:nil forObject:[KonotorWebServices class]];
    
    NSString *pBasePath = [KonotorUtil GetBaseURL];
    
    AFKonotorHTTPClient *httpClient = [[AFKonotorHTTPClient alloc]initWithBaseURL:[NSURL URLWithString:pBasePath]];
    //[httpClient setDefaultHeader:@"Accept" value:@"application/json"];
    [httpClient setDefaultHeader:@"Content-Type" value:@"application/json"];
    
    [httpClient setParameterEncoding:AFKonotorJSONParameterEncoding];
    NSMutableDictionary *dict=[[NSMutableDictionary alloc]init];
    
    [dict setObject:shareEvent.messageID forKey:@"alias"];
    [dict setObject:shareEvent.shareType forKey:@"type"];
    [dict setObject: [FDUtilities getUserAlias] forKey:@"userAlias"];
    
    NSData *pEncodedJSON;
    NSError *pError;
    pEncodedJSON = [NSJSONSerialization dataWithJSONObject:dict  options:NSJSONWritingPrettyPrinted error:&pError];
    //NSString *postPath = [NSString stringWithFormat:[@"/app/s_counter",[KonotorApp GetAppID]];
    NSString *postPath = @"/app/s_counter";
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:postPath parameters:nil];
    [request setHTTPBody:pEncodedJSON];
    [KonotorNetworkUtil SetNetworkActivityIndicator:YES];
    
    AFKonotorHTTPRequestOperation *operation = [[AFKonotorHTTPRequestOperation alloc] initWithRequest:request];
    
    [operation setCompletionBlockWithSuccess:^(AFKonotorHTTPRequestOperation *operation, id JSON){
         [shareEvent setUploadStatus:[NSNumber numberWithInt:EVENT_UPLOADED]];
         [[KonotorDataManager sharedInstance]save];
         [KonotorNetworkUtil SetNetworkActivityIndicator:NO];
         [KonotorUtil EndBackgroundExecutionForTask:bgtask];
     }
     failure:^(AFKonotorHTTPRequestOperation *operation, NSError *error){
         [shareEvent setUploadStatus:[NSNumber numberWithInt:EVENT_NOT_UPLOADED]];
         [[KonotorDataManager sharedInstance]save];
         [KonotorNetworkUtil SetNetworkActivityIndicator:NO];
         [KonotorUtil EndBackgroundExecutionForTask:bgtask];
     }];
    [operation start];
    [shareEvent setUploadStatus:[NSNumber numberWithInt:EVENT_UPLOADING]];
    [[KonotorDataManager sharedInstance]save];
}

+(void) UpdateUserPropertiesWithDictionary:(NSDictionary *) dict withProperty:(KonotorCustomProperty *)prop{
    KonotorCustomProperty *property = prop;
    if(![property serializedData]){
        NSData *dictData = [NSKeyedArchiver archivedDataWithRootObject:dict];
        [property setSerializedData:dictData];
    
        [[KonotorDataManager sharedInstance]save];
    }
    
    //TODO: check if trigger for uploadAllUnuploaded events is needed here
 
    UIBackgroundTaskIdentifier bgtask = [KonotorUtil beginBackgroundExecutionWithExpirationHandler:@selector(HandlePropertyUploadExpiry:) withParameters:property forObject:[KonotorWebServices class]];

    NSString *pBasePath = [KonotorUtil GetBaseURL];
    AFKonotorHTTPClient *httpClient = [[AFKonotorHTTPClient alloc]initWithBaseURL:[NSURL URLWithString:pBasePath]];
    [httpClient setDefaultHeader:@"Content-Type" value:@"application/json"];
    [httpClient setParameterEncoding:AFKonotorJSONParameterEncoding];
    NSMutableDictionary *topLevel=[[NSMutableDictionary alloc]init];
    [topLevel setObject:dict forKey:@"user"];
    [[KonotorDataManager sharedInstance]save];
    
    NSData *pEncodedJSON;
    NSError *pError;
    pEncodedJSON = [NSJSONSerialization dataWithJSONObject:topLevel  options:NSJSONWritingPrettyPrinted error:&pError];
    
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FDUtilities getUserAlias];
    NSString *appKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];

    NSString *putPath = [NSString stringWithFormat:@"services/app/%@/user/%@?t=%@", appID,userAlias,appKey];
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"PUT" path:putPath parameters:nil];
    [request setHTTPBody:pEncodedJSON];
    [KonotorNetworkUtil SetNetworkActivityIndicator:YES];

    AFKonotorHTTPRequestOperation *operation = [[AFKonotorHTTPRequestOperation alloc] initWithRequest:request];
    
    [operation setCompletionBlockWithSuccess:^(AFKonotorHTTPRequestOperation *operation, id JSON){
         [property setUploadStatus:[NSNumber numberWithInt:PROPERTY_UPLOADED]];
         
         //special case
         if([property.key isEqualToString:@"app_version"]){
             //TODO: store app version in secure store if needed
             //[KonotorApp UpdateAppVersion:property.value];
         }
         
         [[KonotorDataManager sharedInstance]save];
         [KonotorNetworkUtil SetNetworkActivityIndicator:NO];
         [KonotorUtil EndBackgroundExecutionForTask:bgtask];
     } failure:^(AFKonotorHTTPRequestOperation *operation, NSError *error){
         [property setUploadStatus:[NSNumber numberWithInt:PROPERTY_NOT_UPLOADED]];
         [[KonotorDataManager sharedInstance]save];
         [KonotorNetworkUtil SetNetworkActivityIndicator:NO];
         [KonotorUtil EndBackgroundExecutionForTask:bgtask];
     }];

    [operation start];
    [property setUploadStatus:[NSNumber numberWithInt:PROPERTY_UPLOADING]];
    [[KonotorDataManager sharedInstance]save];
}

+(void) HandleUserCreateExpiry:(id)parameter{
    return;
}


//TODO: move this to HLCoreServices
+(void) DAUCall{
    
    //TODO: check if user creation is needed here
    
    NSURL *url = [NSURL URLWithString:[KonotorUtil GetBaseURL]];
    AFKonotorHTTPClient *httpClient = [[AFKonotorHTTPClient alloc] initWithBaseURL:url];
    [httpClient setDefaultHeader:@"Content-Type" value:@"application/json"];
    
    
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FDUtilities getUserAlias];
    NSString *appKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];

    NSString *postPath = [NSString stringWithFormat:@"%@%@%@%@%@%@",@"services/app/",appID,@"/user/",userAlias,@"/activity?t=",appKey];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"PUT" path:postPath parameters:nil];
    AFKonotorHTTPRequestOperation *operation = [[AFKonotorHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:nil failure:nil];
    [operation start];
}

+(void) HandleMessageUploadExpiry:(id)parameter{
    return;
}

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