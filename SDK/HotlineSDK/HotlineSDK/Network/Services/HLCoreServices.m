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
#import "KonotorUtil.h"
#import "KonotorDataManager.h"

@implementation HLCoreServices

-(NSURLSessionDataTask *)registerUser:(void (^)(NSError *error))handler{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_USER_REGISTRATION_PATH,appID];

    NSDictionary *info = @{
                           @"user" : @{
                                   @"alias" : [FDUtilities generateUUID],
                                   @"meta"  : [KonotorUtil deviceInfoProperties],
                                   @"adId"  : [FDUtilities getAdID]
                                   }
                           };
    
    NSData *userData = [NSJSONSerialization dataWithJSONObject:info  options:NSJSONWritingPrettyPrinted error:nil];
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:HOTLINE_USER_DOMAIN,[store objectForKey:HOTLINE_DEFAULTS_DOMAIN]]]];
    [request setRelativePath:path andURLParams:@[appKey]];
    request.HTTPMethod = HTTP_METHOD_POST;
    request.HTTPBody = userData;
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(id responseObject, NSError *error) {
        if (!error) {
            NSString *userAlias = responseObject[@"alias"];
            [FDUtilities storeUserAlias:userAlias];
            FDLog(@"User registered successfully 👍");
            handler(nil);
        }else{
            FDLog(@"User registration failed :%@", error);
            handler(error);
        }
    }];
    return task;
}

-(NSURLSessionDataTask *)registerAppWithToken:(NSString *)pushToken forUser:(NSString *)userAlias handler:(void (^)(NSError *))handler{
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    FDSecureStore *store = [FDSecureStore sharedInstance];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:HOTLINE_USER_DOMAIN,[store objectForKey:HOTLINE_DEFAULTS_DOMAIN]]]];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_DEVICE_REGISTRATION_PATH,appID,userAlias];
    NSString *notificationID = [NSString stringWithFormat:@"notification_id=%@",pushToken];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    request.HTTPMethod = HTTP_METHOD_PUT;
    [request setRelativePath:path andURLParams:@[@"notification_type=2", notificationID, appKey]];

    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(id responseObject, NSError *error) {
        if (!error) {
            [store setBoolValue:YES forKey:HOTLINE_DEFAULTS_IS_APP_REGISTERED];
            FDLog(@"Device token updated on server 👍");
        }else{
            FDLog(@"Could not register app :%@", error);
        }
    }];
    return task;
}

-(NSURLSessionDataTask *)updateUserProperties:(NSDictionary *)info{
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FDUtilities getUserAlias];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_USER_PROPERTIES_PATH,appID,userAlias];
    NSData *encodedInfo = [NSJSONSerialization dataWithJSONObject:@{@"user" : info}  options:NSJSONWritingPrettyPrinted error:nil];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:HOTLINE_USER_DOMAIN,[store objectForKey:HOTLINE_DEFAULTS_DOMAIN]]]];
    request.HTTPMethod = HTTP_METHOD_PUT;
    request.HTTPBody = encodedInfo;
    [request setRelativePath:path andURLParams:@[appKey]];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(id responseObject, NSError *error) {
        if (!error) {
            FDLog(@"Pushed user properties to server %@", info);
        }else{
            FDLog(@"Could not update user properties %@", error);
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
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(id responseObject, NSError *error) {
        if (!error) {
            FDLog(@"DAU call made");
        }else{
            FDLog(@"Could not make DAU call %@", error);
        }
    }];
    return task;
}

@end