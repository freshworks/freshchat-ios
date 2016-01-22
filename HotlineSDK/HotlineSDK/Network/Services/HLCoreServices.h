//
//  HLCoreServices.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 03/01/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HLCoreServices : NSObject

-(NSURLSessionDataTask *)registerUser:(void (^)(NSError *))handler;

-(NSURLSessionDataTask *)registerAppWithToken:(NSString *)pushToken forUser:(NSString *)userAlias handler:(void (^)(NSError *))handler;

-(NSURLSessionDataTask *)updateUserProperties:(NSDictionary *)info handler:(void (^)(NSError *error))handler;

+(NSURLSessionDataTask *)DAUCall;

-(NSURLSessionDataTask *)updateSDKBuildNumber:(NSString *)SDKVersion;

@end