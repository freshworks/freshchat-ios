//
//  FDNetworkManager.m
//  FreshdeskSDK
//
//  Created by AravinthChandran on 18/11/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDNetworkManager.h"
#import "FDHTTPSessionManager.h"
#import "FDSecureStore.h"
#import "FDConstants.h"
#import "MobihelpAppState.h"
#import "FDUtilities.h"

@interface FDNetworkManager ()
@property (strong, nonatomic) FDSecureStore *secureStore;
@property (strong, nonatomic) MobihelpAppState *appState;

@end

@implementation FDNetworkManager

#pragma mark - Lazy Instantiation

-(FDSecureStore *)secureStore{
    if(!_secureStore){
        _secureStore = [FDSecureStore sharedInstance];
    }
    return _secureStore;
}

-(MobihelpAppState *)appState{
    if(!_appState){
        _appState = [MobihelpAppState sharedMobihelpAppState];
    }
    return _appState;
}

+(instancetype)sharedNetworkManager{
    static FDNetworkManager *_sharedNetworkManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedNetworkManager = [[self alloc]init];
    });
    return _sharedNetworkManager;
}

-(instancetype)init{
    self = [super init];
    if (self) {
        [self updateSerializer];
    }
    return self;
}

-(void)updateSerializer{
    self.sessionManager                    = [[FDHTTPSessionManager alloc]initWithBaseURL:[FDNetworkManager getBaseURL]];
    self.sessionManager.requestSerializer  = [self constructRequestSerializer];
    self.sessionManager.responseSerializer = [self constructResponseSerializer];
}

+(NSURL *)getBaseURL{
    FDSecureStore *secureStore = [FDSecureStore sharedInstance];
    BOOL isSSLEnabled = [FDUtilities isSSLEnabled];
    NSString *supportSite = [NSString stringWithFormat:isSSLEnabled ? @"https://%@" : @"http://%@", [secureStore objectForKey:MOBIHELP_DEFAULTS_SUPPORT_SITE]];
    return [NSURL URLWithString:supportSite];
}

-(FDJSONResponseSerializer *)constructResponseSerializer{
    return [FDJSONResponseSerializer serializer];
}

-(FDJSONRequestSerializer *)constructRequestSerializer{
    FDJSONRequestSerializer *requestSerializer = [FDJSONRequestSerializer serializer];
    FDSecureStore *secureStore    = [FDSecureStore sharedInstance];
    NSString *appKey              = [secureStore objectForKey:MOBIHELP_DEFAULTS_APP_KEY];
    NSString *appSecret           = [secureStore objectForKey:MOBIHELP_DEFAULTS_APP_SECRET];
    NSString *stringToEncode      = [NSString stringWithFormat:@"%@:%@",appKey,appSecret];
    NSString *appAuthHeaderEncoded = [FDUtilities base64EncodedStringFromString:stringToEncode];
    [requestSerializer setValue:@"2" forHTTPHeaderField:MOBIHELP_API_HEADER_API_VERSION];
    [requestSerializer setValue:appAuthHeaderEncoded forHTTPHeaderField:MOBIHELP_API_HEADER_AUTHORIZATION];
    [requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [requestSerializer setValue:appKey forHTTPHeaderField:MOBIHELP_API_HEADER_APPID];
    return requestSerializer;
}

-(NSString *)addSDKParams:(NSString *)existingURL{
    NSString *additionalParameters = [NSString stringWithFormat:MOBIHELP_API_ADDITIONAL_PARAMETERS,MOBIHELP_SDK_VERSION];
    if([existingURL rangeOfString:@"?"].location == NSNotFound){
        return [existingURL stringByAppendingString:[NSString stringWithFormat:@"?%@",additionalParameters]];
    }else{
        return [existingURL stringByAppendingString:[NSString stringWithFormat:@"&%@",additionalParameters]];
    }
}

-(void)checkAndUpdateAppState:(id)responseObject{
    if ([responseObject isKindOfClass:[NSDictionary class]]) {
        if (responseObject[@"status_code"]) {
            NSInteger statusCode       = [[responseObject valueForKey:@"status_code"]integerValue];
            self.appState.isAppDeleted = (statusCode == MOBIHELP_STATUS_CODE_APP_DELETED);
            self.appState.isAppInvalid = (statusCode == MOBIHELP_STATUS_CODE_INVALID_APP_CREDENTIALS);
         }
        self.appState.isAccountSuspended = [responseObject[@"account_suspended"]boolValue];
    }
}

-(NSURLSessionDataTask *)GET:(NSString *)URLString parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *, id))success failure:(void (^)(NSURLSessionDataTask *, NSError *))failure{
    URLString = [self addSDKParams:URLString];
    return [self.sessionManager GET:URLString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        [self checkAndUpdateAppState:responseObject];
        NSError *appStateError = [self.appState getAppErrorForCurrentState];
        if (appStateError) {
            if (failure){
                failure(task, appStateError);
            }
        }else{
            if (success) success(task, responseObject);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        failure(nil,error);
    }];
}

-(NSURLSessionDataTask *)POST:(NSString *)URLString parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *, id))success failure:(void (^)(NSURLSessionDataTask *, NSError *))failure{
    URLString = [self addSDKParams:URLString];
    return [self.sessionManager POST:URLString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        [self checkAndUpdateAppState:responseObject];
        NSError *appStateError = [self.appState getAppErrorForCurrentState];
        if (appStateError) {
            if (failure){
                failure(task, appStateError);
            }
        }else{
            if (success) success(task, responseObject);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        failure(nil,error);
    }];
}

/* NSURLSession clears content-length before sending multipart request,
   Implemented the suggested workaround https://github.com/AFNetworking/AFNetworking/issues/1398 */

-(NSURLSessionDataTask *)POST:(NSString *)URLString parameters:(id)parameters constructingBodyWithBlock:(void (^)(id<FDMultipartFormData>))block success:(void (^)(NSURLSessionDataTask *task, id responseObject))success failure:(void (^)(NSURLSessionDataTask *, NSError *))failure{
    URLString = [self addSDKParams:URLString];
    URLString = [[NSURL URLWithString:URLString relativeToURL:self.sessionManager.baseURL] absoluteString];

    NSError *serializationError;
    NSMutableURLRequest *multipartRequest = [self.sessionManager.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:URLString parameters:parameters constructingBodyWithBlock:^(id<FDMultipartFormData> formData) { block(formData); } error:&serializationError];
    
    if (serializationError){
        dispatch_async(dispatch_get_main_queue(), ^{ if (failure) {failure(nil, serializationError); } });
        return nil;
    }
    
    NSURL *tempFileURL = [self getTempFileURL];
    __block NSURLSessionDataTask *task;
    [self.sessionManager.requestSerializer requestWithMultipartFormRequest:multipartRequest writingStreamContentsToFile:tempFileURL completionHandler:^(NSError *error) {
        task = [self.sessionManager uploadTaskWithRequest:multipartRequest fromFile:tempFileURL progress:nil completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
            [self checkAndUpdateAppState:responseObject];
            NSError *appStateError = [self.appState getAppErrorForCurrentState];
            if (error || appStateError) {
                if (failure){
                    if(error)
                        failure(task, error);
                    else if(appStateError)
                        failure(task, error);
                }
            }else{
                if (success) success(task, responseObject);
            }
        }];
        [task resume];
    }];
    
    return task;
}

-(NSURL *)getTempFileURL{
    NSString* tmpFilename = [NSString stringWithFormat:@"mh_tmp_%f", [NSDate timeIntervalSinceReferenceDate]];
    return [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:tmpFilename]];
}

@end