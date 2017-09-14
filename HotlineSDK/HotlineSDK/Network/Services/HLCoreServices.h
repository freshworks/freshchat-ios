//
//  HLCoreServices.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 03/01/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.h"
#import "FDResponseInfo.h"

@interface HLCoreServices : NSObject

-(NSURLSessionDataTask *)registerUser:(void (^)(NSError *))handler;

-(NSURLSessionDataTask *)registerAppWithToken:(NSString *)pushToken forUser:(NSString *)userAlias handler:(void (^)(NSError *))handler;

+(NSURLSessionDataTask *)performDAUCall;

+(NSURLSessionDataTask *)performSessionCall;

-(NSURLSessionDataTask *)updateSDKBuildNumber:(NSString *)SDKVersion;

+(NSURLSessionDataTask *)registerUserConversationActivity :(Message *)message;

+(void)uploadUnuploadedProperties;

+(NSURLSessionDataTask *)fetchRemoreConfig;

+(NSURLSessionDataTask *)performHeartbeatCall;

+(void)sendLatestUserActivity:(HLChannel *)channel;

+(NSURLSessionDataTask *)trackUninstallForUser:(NSDictionary *) userAlias withCompletion:(void (^)(NSError *))completion;

+(NSURLSessionDataTask *)fetchTypicalReply:(void (^)(FDResponseInfo *responseInfo, NSError *error))handler;

@end
