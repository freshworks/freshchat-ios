//
//  HLCoreServices.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 03/01/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "HLCoreServices.h"
#import "HLAPIClient.h"
#import "HLServiceRequest.h"
#import "FDSecureStore.h"
#import "HLMacros.h"
#import "FDUtilities.h"
#import "KonotorDataManager.h"
#import "HLConstants.h"
#import "FDResponseInfo.h"
#import "KonotorCustomProperty.h"

@implementation HLCoreServices

-(NSURLSessionDataTask *)updateSDKBuildNumber:(NSString *)SDKVersion{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FDUtilities getUserAlias];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_UPDATE_SDK_BUILD_NUMBER_PATH,appID,userAlias];
    NSString *clientVersion = [NSString stringWithFormat:@"clientVersion=%@",SDKVersion];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:HOTLINE_USER_DOMAIN,[store objectForKey:HOTLINE_DEFAULTS_DOMAIN]]]];
    [request setRelativePath:path andURLParams:@[appKey,clientVersion,@"clientType=2"]];
    request.HTTPMethod = HTTP_METHOD_PUT;
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
        if (!error) {
            [store setObject:HOTLINE_SDK_BUILD_NUMBER forKey:HOTLINE_DEFAULTS_SDK_BUILD_NUMBER];
            FDLog(@"SDK build number updated to server");
        }else{
            FDLog(@"SDK build number could not be updated %@", error);
            FDLog(@"Response : %@", responseInfo.response);
        }
    }];
    return task;
}

-(NSURLSessionDataTask *)registerUser:(void (^)(NSError *error))handler{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_USER_REGISTRATION_PATH,appID];

    NSDictionary *info = @{
                           @"user" : @{
                                   @"alias" : [FDUtilities getUserAlias],
                                   @"meta"  : [FDUtilities deviceInfoProperties],
                                   @"adId"  : [FDUtilities getAdID]
                                   }
                           };
    
    NSData *userData = [NSJSONSerialization dataWithJSONObject:info  options:NSJSONWritingPrettyPrinted error:nil];
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:HOTLINE_USER_DOMAIN,[store objectForKey:HOTLINE_DEFAULTS_DOMAIN]]]];
    [request setRelativePath:path andURLParams:@[appKey]];
    request.HTTPMethod = HTTP_METHOD_POST;
    request.HTTPBody = userData;
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
        if (!error) {
            [[FDSecureStore sharedInstance] setBoolValue:YES forKey:HOTLINE_DEFAULTS_IS_USER_REGISTERED];
            FDLog(@"User registered successfully 👍");
            if (handler) handler(nil);
        }else{
            FDLog(@"User registration failed :%@", error);
            FDLog(@"Response : %@", responseInfo.response);
            if (handler) handler(error);
        }
    }];
    return task;
}

-(NSURLSessionDataTask *)registerAppWithToken:(NSString *)pushToken forUser:(NSString *)userAlias handler:(void (^)(NSError *))handler{
    if (!userAlias || !pushToken) return nil;
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    FDSecureStore *store = [FDSecureStore sharedInstance];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:HOTLINE_USER_DOMAIN,[store objectForKey:HOTLINE_DEFAULTS_DOMAIN]]]];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_DEVICE_REGISTRATION_PATH,appID,userAlias];
    NSString *notificationID = [NSString stringWithFormat:@"notification_id=%@",pushToken];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    request.HTTPMethod = HTTP_METHOD_PUT;
    [request setRelativePath:path andURLParams:@[@"notification_type=2", notificationID, appKey]];

    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
        if (!error) {
            [store setBoolValue:YES forKey:HOTLINE_DEFAULTS_IS_DEVICE_TOKEN_REGISTERED];
            FDLog(@"Device token updated on server 👍");
        }else{
            FDLog(@"Could not register app :%@", error);
            FDLog(@"Response : %@", responseInfo.response);
        }
    }];
    return task;
}

+(void)uploadUnuploadedProperties{
    
    static dispatch_group_t serviceGroup = nil;
    static dispatch_queue_t dispatchQueue = nil;
    
    if (!serviceGroup) {
        serviceGroup = dispatch_group_create();
    }
    
    if(!dispatchQueue){
        dispatchQueue = dispatch_queue_create("com.freshdesk.hotline.uploadprops",DISPATCH_QUEUE_SERIAL);
    }
    
    dispatch_async(dispatchQueue, ^{
        
        dispatch_group_wait(serviceGroup,DISPATCH_TIME_FOREVER);
        
        [[KonotorDataManager sharedInstance].mainObjectContext performBlock:^{
            
            dispatch_group_enter(serviceGroup);
            
            if (![FDUtilities isUserRegistered]) {
                dispatch_group_leave(serviceGroup);
                return;
            }
            
            NSMutableDictionary *info = [NSMutableDictionary new];
            NSMutableDictionary *userInfo = [NSMutableDictionary new];
            
            NSArray *unuploadedProperties = [KonotorCustomProperty getUnuploadedProperties];
            if (unuploadedProperties.count > 0) {
                NSMutableDictionary *metaInfo = [NSMutableDictionary new];
                for (int i=0; i<unuploadedProperties.count; i++) {
                    KonotorCustomProperty *property = unuploadedProperties[i];
                    if (property.key) {
                        if (property.isUserProperty) {
                            userInfo[property.key] = property.value;
                        }else{
                            metaInfo[property.key] = property.value;
                        }
                    }
                }
                userInfo[@"meta"] = metaInfo;
                info[@"user"] = userInfo;
            }else{
                dispatch_group_leave(serviceGroup);
                return;
            }
            
            [self updateUserProperties:info handler:^(NSError *error) {
                if (!error) {
                    for (int i=0; i<unuploadedProperties.count; i++) {
                        KonotorCustomProperty *property = unuploadedProperties[i];
                        property.uploadStatus = @1;
                    }
                }

                [[KonotorDataManager sharedInstance]save];
                
                dispatch_group_leave(serviceGroup);
            }];
        }];
      });
}

+(NSURLSessionDataTask *)updateUserProperties:(NSDictionary *)info handler:(void (^)(NSError *error))handler{
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FDUtilities getUserAlias];
    if (!userAlias) return nil;
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_USER_PROPERTIES_PATH,appID,userAlias];
    NSData *encodedInfo = [NSJSONSerialization dataWithJSONObject:info  options:NSJSONWritingPrettyPrinted error:nil];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:HOTLINE_USER_DOMAIN,[store objectForKey:HOTLINE_DEFAULTS_DOMAIN]]]];
    request.HTTPMethod = HTTP_METHOD_PUT;
    request.HTTPBody = encodedInfo;
    [request setRelativePath:path andURLParams:@[appKey]];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
        if (!error) {
            FDLog(@"Pushed properties to server %@", info);
            if (handler) handler(nil);
        }else{
            if (handler) handler(error);
            FDLog(@"Could not update user properties %@", error);
            FDLog(@"Response : %@", responseInfo.response);
        }
    }];
    return task;
}

+(NSURLSessionDataTask *)DAUCall{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FDUtilities getUserAlias];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_DAU_PATH,appID,userAlias];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:HOTLINE_USER_DOMAIN,[store objectForKey:HOTLINE_DEFAULTS_DOMAIN]]]];
    request.HTTPMethod = HTTP_METHOD_PUT;
    [request setRelativePath:path andURLParams:@[appKey]];
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
        if (!error) {
            FDLog(@"DAU call made");
        }else{
            FDLog(@"Could not make DAU call %@", error);
            FDLog(@"Response : %@", responseInfo.response);
        }
    }];
    return task;
}

+(NSURLSessionDataTask *)registerUserConversationActivity :(KonotorMessage *)message{
    
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FDUtilities getUserAlias];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_USER_CONVERSATION_ACTIVITY,appID,userAlias];
    
    NSMutableDictionary *info = [NSMutableDictionary new];
    
    if (message.belongsToConversation.conversationAlias) {
        info[@"conversationId"] = message.belongsToConversation.conversationAlias;
    }
    
    if (message.belongsToChannel.channelID) {
        info[@"channelId"] = message.belongsToChannel.channelID;
    }
    
    if (message.createdMillis) {
        info[@"readUpto"] = message.createdMillis;
    }
    
    NSData *userData = [NSJSONSerialization dataWithJSONObject:info  options:NSJSONWritingPrettyPrinted error:nil];
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:HOTLINE_USER_DOMAIN,[store objectForKey:HOTLINE_DEFAULTS_DOMAIN]]]];
    [request setRelativePath:path andURLParams:@[appKey]];
    request.HTTPMethod = HTTP_METHOD_POST;
    request.HTTPBody = userData;
    
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
        if (!error) {
            FDLog(@"Successful conversation request")
        }else{
            FDLog(@"Could not make register user conversation call %@", error);
            FDLog(@"Response : %@", responseInfo.response);
        }
    }];
    return task;
}

@end