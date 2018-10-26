//
//  HLCoreServices.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 03/01/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCMessages.h"
#import "FCResponseInfo.h"

@interface FCCoreServices : NSObject

-(NSURLSessionDataTask *)registerUser:(void (^)(NSError *))handler;

-(NSURLSessionDataTask *)registerAppWithToken:(NSString *)pushToken forUser:(NSString *)userAlias handler:(void (^)(NSError *))handler;

+(NSURLSessionDataTask *)performDAUCall;

+(NSURLSessionDataTask *)performSessionCall;

-(NSURLSessionDataTask *)updateSDKBuildNumber:(NSString *)SDKVersion;

+(NSURLSessionDataTask *)validateJwtToken:(NSString *)jwtIdToken completion:(void(^)(BOOL valid, NSError *error))handler;

+(NSURLSessionDataTask *)registerUserConversationActivity :(FCMessages *)message;

+(void)uploadUnuploadedProperties;

+(void)uploadUnuploadedPropertiesWithForceUpdate:(BOOL) forceUpdate;

+(NSURLSessionDataTask *)fetchRemoteConfig;

+(NSURLSessionDataTask *)performHeartbeatCall;

+(void)sendLatestUserActivity:(FCChannels *)channel;

+(NSURLSessionDataTask *)trackUninstallForUser:(NSDictionary *) userAlias withCompletion:(void (^)(NSError *))completion;

+(NSURLSessionDataTask *)fetchTypicalReply:(void (^)(FCResponseInfo *responseInfo, NSError *error))handler;

+(NSURLSessionDataTask *)restoreUserWithExtId:(NSString *)extId restoreId:(NSString *)restoreIdVal withCompletion:(void (^)(NSError *))completion;

+(NSURLSessionDataTask *)restoreUserWithJwtToken:(NSString *)jwtIdToken withCompletion:(void (^)(NSError *))completion;

+(void) resetUserData:(void (^)())completion;

+(void) setAsUploadedTo:(NSArray *) properties withCompletion:(void (^)())completion;

+(NSArray *) updatePropertiesTo: (NSMutableDictionary *) userInfo;

@end
