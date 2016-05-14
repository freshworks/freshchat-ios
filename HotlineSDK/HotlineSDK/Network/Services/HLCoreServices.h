//
//  HLCoreServices.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 03/01/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KonotorMessage.h"

@interface HLCoreServices : NSObject

-(NSURLSessionDataTask *)registerUser:(void (^)(NSError *))handler;

-(NSURLSessionDataTask *)registerAppWithToken:(NSString *)pushToken forUser:(NSString *)userAlias handler:(void (^)(NSError *))handler;

+(NSURLSessionDataTask *)DAUCall:(void (^)(NSError *))completion;

-(NSURLSessionDataTask *)updateSDKBuildNumber:(NSString *)SDKVersion;

+(NSURLSessionDataTask *)registerUserConversationActivity :(KonotorMessage *)message;

+(void)uploadUnuploadedProperties;

@end