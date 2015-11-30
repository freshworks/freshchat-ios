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
#import "KonotorApp.h"
#import "KonotorUser.h"
#import "KonotorMessage.h"
#import "KonotorMessageBinary.h"
#import "KonotorUtil.h"
#import "Konotor.h"
#import "KonotorCustomProperties.h"
#import "KonotorShareMessageEvent.h"

#define MESSAGE_NOT_UPLOADED 0
#define MESSAGE_UPLOADING 1
#define MESSAGE_UPLOADED 2

#define PROPERTY_NOT_UPLOADED 0
#define PROPERTY_UPLOADING 1
#define PROPERTY_UPLOADED 2

#define EVENT_NOT_UPLOADED 0
#define EVENT_UPLOADING 1
#define EVENT_UPLOADED 2

@implementation KonotorWebServices

+(void) HandlePropertyUploadExpiry:(id)parameter{
    KonotorCustomProperty *prop = (KonotorCustomProperty *)parameter;
    [prop setUploadStatus:[NSNumber numberWithInt:PROPERTY_NOT_UPLOADED]];
}

+(void) UpdateAppVersion:(NSString *) appVersion{
    [KonotorUser setCustomUserProperty:appVersion forKey:@"app_version"];
}

+(void) UpdateSdkVersion: (NSString *) sdkVersion{
    
    if(![KonotorUser isUserCreatedOnServer]){
        return;
    }
    
    NSString *pBasePath = [KonotorUtil GetBaseURL];
    AFKonotorHTTPClient *httpClient = [[AFKonotorHTTPClient alloc]initWithBaseURL:[NSURL URLWithString:pBasePath]];
    [httpClient setDefaultHeader:@"Content-Type" value:@"application/x-www-form-urlencoded"];
    
    [httpClient setParameterEncoding:AFKonotorJSONParameterEncoding];
    NSMutableDictionary *topLevel=[[NSMutableDictionary alloc]init];

    NSData *pEncodedJSON;
    NSError *pError;
    pEncodedJSON = [NSJSONSerialization dataWithJSONObject:topLevel  options:NSJSONWritingPrettyPrinted error:&pError];
    NSString *putPath = [NSString stringWithFormat:@"services/app/%@/user/%@/client?t=%@&clientVersion=%@&clientType=2", [KonotorApp GetAppID],[KonotorUser GetUserAlias],[KonotorApp GetAppKey],sdkVersion];
    
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"PUT" path:putPath parameters:nil];
    [KonotorNetworkUtil SetNetworkActivityIndicator:YES];
    
    AFKonotorHTTPRequestOperation *operation = [[AFKonotorHTTPRequestOperation alloc] initWithRequest:request];
    
    [operation setCompletionBlockWithSuccess:^(AFKonotorHTTPRequestOperation *operation, id JSON){
         [KonotorApp UpdateSDKVersion:sdkVersion];
         [[KonotorDataManager sharedInstance]save];
         
         [KonotorNetworkUtil SetNetworkActivityIndicator:NO];
         
         
     }
    failure:^(AFKonotorHTTPRequestOperation *operation, NSError *error){
         
         [KonotorNetworkUtil SetNetworkActivityIndicator:NO];
         
         
     }];
    
    [operation start];

}

+(void) sendShareMessageEvent:(KonotorShareMessageEvent *)shareEvent{
 
    if(![KonotorUser isUserCreatedOnServer]){
        [KonotorUser CreateUserOnServerIfNotPresentandPerformSelectorIfSuccessful:@selector(UploadAllUnuploadedEvents) withObject:[KonotorCustomProperty class] withSuccessParameter:nil ifFailure:nil withObject:nil withFailureParameter:nil];
        return;
    }
    
    NSUInteger bgtask = [KonotorUtil beginBackgroundExecutionWithExpirationHandler:@selector(HandleUserCreateExpiry:) withParameters:nil forObject:[KonotorWebServices class]];
    
    NSString *pBasePath = [KonotorUtil GetBaseURL];
    
    AFKonotorHTTPClient *httpClient = [[AFKonotorHTTPClient alloc]initWithBaseURL:[NSURL URLWithString:pBasePath]];
    //[httpClient setDefaultHeader:@"Accept" value:@"application/json"];
    [httpClient setDefaultHeader:@"Content-Type" value:@"application/json"];
    
    [httpClient setParameterEncoding:AFKonotorJSONParameterEncoding];
    NSMutableDictionary *dict=[[NSMutableDictionary alloc]init];
    
    
    [dict setObject:shareEvent.messageID forKey:@"messageId"];
    [dict setObject:shareEvent.shareType forKey:@"type"];
    [dict setObject: [KonotorUser GetUserAlias] forKey:@"userAlias"];
    
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

    if(![KonotorUser isUserCreatedOnServer]){
        [KonotorUser CreateUserOnServerIfNotPresentandPerformSelectorIfSuccessful:@selector(UploadAllUnuploadedProperties) withObject:[KonotorCustomProperty class] withSuccessParameter:nil ifFailure:nil withObject:nil withFailureParameter:nil];
        return;
        
    }
 
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
    NSString *putPath = [NSString stringWithFormat:@"services/app/%@/user/%@?t=%@", [KonotorApp GetAppID],[KonotorUser GetUserAlias],[KonotorApp GetAppKey]];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"PUT" path:putPath parameters:nil];
    [request setHTTPBody:pEncodedJSON];
    [KonotorNetworkUtil SetNetworkActivityIndicator:YES];
    
    
    AFKonotorHTTPRequestOperation *operation = [[AFKonotorHTTPRequestOperation alloc] initWithRequest:request];
    
    [operation setCompletionBlockWithSuccess:^(AFKonotorHTTPRequestOperation *operation, id JSON){
         [property setUploadStatus:[NSNumber numberWithInt:PROPERTY_UPLOADED]];
         
         //special case
         if([property.key isEqualToString:@"app_version"]){
             [KonotorApp UpdateAppVersion:property.value];
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

+(void) DAUCall{
    
    if(![KonotorUser isUserCreatedOnServer]){
        return;
    }
    
    NSURL *url = [NSURL URLWithString:[KonotorUtil GetBaseURL]];
    AFKonotorHTTPClient *httpClient = [[AFKonotorHTTPClient alloc] initWithBaseURL:url];
    [httpClient setDefaultHeader:@"Content-Type" value:@"application/json"];
    
    NSString *app = [KonotorApp GetAppID];
    NSString *user = [KonotorUser GetUserAlias];
    NSString *token = [KonotorApp GetAppKey];

    NSString *postPath = [NSString stringWithFormat:@"%@%@%@%@%@%@",@"services/app/",app,@"/user/",user,@"/activity?t=",token];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"PUT" path:postPath parameters:nil];
    AFKonotorHTTPRequestOperation *operation = [[AFKonotorHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:nil failure:nil];
    [operation start];
}

+(void) AddPushDeviceToken: (NSString *) deviceToken{
    NSURL *url = [NSURL URLWithString:[KonotorUtil GetBaseURL]];
    AFKonotorHTTPClient *httpClient = [[AFKonotorHTTPClient alloc] initWithBaseURL:url];
    [httpClient setDefaultHeader:@"Content-Type" value:@"application/json"];
    
    NSString *app = [KonotorApp GetAppID];
    NSString *user = [KonotorUser GetUserAlias];
    NSString *token = [KonotorApp GetAppKey];
    
    if (!user || ![KonotorUser isUserCreatedOnServer] ){
        return;
    }
    
    NSString *postPath = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@",@"services/app/",app,@"/user/",user,@"/notification?notification_type=2&notification_id=",deviceToken, @"&t=",token];
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"PUT" path:postPath parameters:nil];
    AFKonotorHTTPRequestOperation *operation = [[AFKonotorHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFKonotorHTTPRequestOperation *operation, id responseObject){
         [KonotorApp successfullyUpdatedDeviceTokenOnServer];
     } failure:nil];
    [operation start];
}

+(void) HandleMessageUploadExpiry:(id)parameter{
    return;
}


+(void) uploadMessage:(KonotorMessage *)pMessage toConversation:(KonotorConversation *)conversation onChannel:(HLChannel *)channel{
    if(![pMessage isMarkedForUpload]){
        pMessage.isMarkedForUpload = YES;
        [[KonotorDataManager sharedInstance]save];
    }
    
    if(![KonotorUser isUserCreatedOnServer]){
        [KonotorUser CreateUserOnServerIfNotPresentandPerformSelectorIfSuccessful:@selector(UploadAllUnuploadedMessages) withObject:[KonotorMessage class] withSuccessParameter:nil ifFailure:@selector(UploadFailedNotifcation:) withObject:[Konotor class] withFailureParameter:pMessage.messageAlias];
        return;
    }
    
    UIBackgroundTaskIdentifier bgtask = [KonotorUtil beginBackgroundExecutionWithExpirationHandler:@selector(HandleMessageUploadExpiry:) withParameters:nil forObject:[KonotorWebServices class]];
    
    NSString *app = [KonotorApp GetAppID];
    NSString *user = [KonotorUser GetUserAlias];
    NSString *token = [KonotorApp GetAppKey];

    __block NSString *messageAlias = pMessage.messageAlias;
    
    if([[pMessage uploadStatus]intValue] == MESSAGE_UPLOADED || [[pMessage uploadStatus]intValue] == MESSAGE_UPLOADING){
        return;
    }else{
        pMessage.uploadStatus = @(MESSAGE_UPLOADING);
        [[KonotorDataManager sharedInstance]save];
    }
   
    NSURL *url = [NSURL URLWithString:[KonotorUtil GetBaseURL]];
    AFKonotorHTTPClient *httpClient = [[AFKonotorHTTPClient alloc] initWithBaseURL:url];
    
    NSString *postPath = [NSString stringWithFormat:@"%@%@%@%@%@%@",@"services/app/",app,@"/user/",user,@"/feedback/message/v2?t=",token];
    
    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:postPath parameters:nil constructingBodyWithBlock: ^(id <AFKonotorMultipartFormData>formData) {
        
        [formData appendPartWithFormData:[[pMessage getJSON] dataUsingEncoding:NSUTF8StringEncoding] name:@"message"];
        [formData appendPartWithFormData:[channel.channelID.stringValue dataUsingEncoding:NSUTF8StringEncoding]
                                    name:@"channelId"];
        
        if (conversation) {
            [formData appendPartWithFormData:[conversation.conversationAlias dataUsingEncoding:NSUTF8StringEncoding] name:@"conversationId"];
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
            KonotorUser* user = [KonotorUser GetCurrentlyLoggedInUser];
            NSString *conversationID = [messageInfo[@"hostConversationId"] stringValue];
            KonotorConversation *newConversation = [KonotorConversation createConversationWithID:conversationID ForChannel:channel];
            pMessage.belongsToConversation = newConversation;
            [user addHasConversationsObject:newConversation];
        }else{
            pMessage.belongsToConversation = conversation;
        }

        [KonotorNetworkUtil SetNetworkActivityIndicator:NO];
        pMessage.uploadStatus = @(MESSAGE_UPLOADED);
        pMessage.messageAlias = [messageInfo[@"messageId"]stringValue];
        [[KonotorDataManager sharedInstance]save];
        [KonotorUtil EndBackgroundExecutionForTask:bgtask];
        [Konotor performSelector:@selector(UploadFinishedNotifcation:) withObject:messageAlias];
     }
     
    failure:^(AFKonotorHTTPRequestOperation *operation, NSError *error){
        [KonotorNetworkUtil SetNetworkActivityIndicator:NO];
        pMessage.uploadStatus = @(MESSAGE_NOT_UPLOADED);
        [[KonotorDataManager sharedInstance]save];
        [Konotor performSelector:@selector(UploadFailedNotifcation:) withObject:messageAlias];
        [KonotorUtil EndBackgroundExecutionForTask:bgtask];
     }];
    
    [operation start];
}

@end