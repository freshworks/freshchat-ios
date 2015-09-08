//
//  FDNetworkManager.h
//  FreshdeskSDK
//
//  Created by AravinthChandran on 18/11/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FDAPI.h"
#import "FDNetworking.h"

@interface FDNetworkManager : NSObject

@property (strong, nonatomic) FDHTTPSessionManager *sessionManager;

+(instancetype)sharedNetworkManager;

//Update serializer when changing the app credentials
-(void)updateSerializer;

+(NSURL *)getBaseURL;

- (NSURLSessionDataTask *)GET:(NSString *)URLString parameters:(id)parameters
                      success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                      failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

- (NSURLSessionDataTask *)POST:(NSString *)URLString parameters:(id)parameters
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

- (NSURLSessionDataTask *)POST:(NSString *)URLString parameters:(id)parameters
     constructingBodyWithBlock:(void (^)(id <FDMultipartFormData> formData))block
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

@end