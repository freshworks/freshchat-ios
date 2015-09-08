//
//  FDAPIClient.m
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 29/04/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "Mobihelp.h"
#import "FDAPIClient.h"
#import "FDDateUtil.h"
#import "FDSecureStore.h"
#import "FDMacros.h"
#import "FDUtilities.h"
#import "FDError.h"

@interface FDAPIClient ()

@property (strong, nonatomic) FDSecureStore    *secureStore;
@property (strong, nonatomic) FDNetworkManager *networkManager;
@property (atomic) int retryCount;
@property (atomic) BOOL retryEnabled;

@end 

@implementation FDAPIClient


- (id) init {
    self = [super init];
    if(self){
        self.retryCount = 0;
    }
    return self;
}

#pragma mark - Lazy Instantiations

-(FDSecureStore *)secureStore{
    if(!_secureStore){
        _secureStore = [FDSecureStore sharedInstance];
    }
    return _secureStore;
}

-(FDNetworkManager *)networkManager{
    if(!_networkManager){
        _networkManager = [FDNetworkManager sharedNetworkManager];
    }
    return _networkManager;
}

#pragma mark - Retry Helpers

-(BOOL)retryExceeded{
    return (self.retryEnabled && self.retryCount > 3);
}

-(void)trackRetry{
    self.retryEnabled = YES;
    self.retryCount++;
}

-(void)resetRetry{
    self.retryEnabled = NO;
    self.retryCount = 0;
}

#pragma mark - User, Device Registration

-(NSURLSessionDataTask *)registerDeviceWithInfo:(NSDictionary*)params withCompletion:(void(^)(NSDictionary *response, NSError *error))completion{
    NSString *deviceRegistrationURL = MOBIHELP_API_REGISTER_DEVICE;
    return [self.networkManager POST:deviceRegistrationURL parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        [self.secureStore setBoolValue:YES forKey:MOBIHELP_DEFAULTS_DEVICE_REGISTRATION_STATUS];
        NSString *apiKey = responseObject[@"api_key"];
        if (apiKey) {
            [self.secureStore setObject:apiKey forKey:MOBIHELP_DEFAULTS_API_KEY];
        }
        completion(responseObject,nil);
        FDLog(@"FDAPICLIENT: Device Registration Successful");
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
        FDLog(@"FDAPICLIENT: Device Registration Failed");
    }];
}

-(NSURLSessionDataTask *)registerUserRequest:(NSDictionary *)params completion:(void (^)(NSDictionary *response, NSError *error))completion{
    FDLog(@"Register User Called %d times" , self.retryCount );
    NSString *userRegistrationURL = MOBIHELP_API_REGISTER_USER;
    return [self.networkManager POST:userRegistrationURL parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil, error);
    }];
}

-(NSURLSessionDataTask *)registerUser:(NSDictionary *)params completion:(void (^)(NSDictionary *response, NSError *error))completion{
    if([self retryExceeded]){
        FDError *error = [[FDError alloc]initWithError:MOBIHELP_UNEXPECTED_ERROR];
        if(completion) completion(nil,error);
        return nil;
    }
    NSDictionary *registrationInfo = [FDUtilities getRegistrationInformation];
    return [self registerUserRequest:registrationInfo completion:^(NSDictionary *response, NSError *error) {
        if (!error) {
            if(response){
                NSInteger statusCode = [[response valueForKey:@"status_code"]integerValue];
                if(statusCode == 0){ // Success
                    [self.secureStore setObject:[response valueForKey:@"api_key"] forKey:MOBIHELP_DEFAULTS_API_KEY];
                    [self.secureStore setBoolValue:YES forKey:MOBIHELP_DEFAULTS_USER_REGISTRATION_STATUS];
                }
                else if ( statusCode == 40 ){ // Duplicate Device ID
                    [self.secureStore removeObjectWithKey:MOBIHELP_DEFAULTS_DEVICE_UUID]; // remove to regenerate
                    [self trackRetry];
                    [self registerUser:params completion: ^(NSDictionary *response, NSError *error){
                        [self resetRetry];
                        completion(response,error);
                    }];
                    return;
                }
                else {
                    error = [[FDError alloc]initWithError: MOBIHELP_UNEXPECTED_ERROR];
                }
            }
            else {
                error = [[FDError alloc]initWithError: MOBIHELP_ERROR_INVALID_RESPONSE];
            }
        }
        [self resetRetry];
        completion(response,error);
    }];
}

#pragma mark - App  Configuration

-(NSURLSessionDataTask *)getAppConfigurationWithCompletion:(void(^)(NSDictionary *response, NSError *error))completion{
    return [self.networkManager GET:MOBIHELP_API_APP_CONFIG parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}

#pragma mark - Articles Fetching

-(NSURLSessionDataTask *)fetchAllArticlesWithParams:(NSDictionary *)params completion:(void(^)(id articles, NSError *error))completion{
    NSString *articlesURL     = nil;
    NSString *lastUpdatedTime = [FDDateUtil solutionsLastUpdatedWebFriendlyTime];
    if (lastUpdatedTime) {
        articlesURL = [NSString stringWithFormat:MOBIHELP_API_ARTICLES_WITH_LAST_UPDATED_TIME,lastUpdatedTime];
    }else{
        articlesURL = MOBIHELP_API_ARTICLES;
    }
    return [self.networkManager GET:articlesURL parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        [self.secureStore setObject:[NSDate date] forKey:MOBIHELP_DEFAULTS_SOLUTIONS_LAST_UPDATED_TIME_V2];
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil, error);
    }];
}

#pragma mark - Ticket Creation and Fetching

//Create ticket if the user is registered else register the user first and then create the ticket
-(NSURLSessionDataTask *)createTicketWithContent:(FDTicketContent *)ticketContent completion:(void (^) (NSDictionary *response, NSError *error))completion{
    NSString *newTicketURL = MOBIHELP_API_CREATE_NEW_TICKET;
    NSString *apiKey       = [self.secureStore objectForKey:MOBIHELP_DEFAULTS_API_KEY];
    [self.networkManager.sessionManager.requestSerializer setAuthorizationHeaderFieldWithUsername:apiKey password:@"x"];
    __block NSURLSessionDataTask *task;
    [FDUtilities getDeviceAppInfoCompletionHandler:^(NSData *data) {
        NSDictionary *params = [FDUtilities getTicketInfoWithContent:ticketContent];
        task = [self.networkManager POST:newTicketURL parameters:params constructingBodyWithBlock:^(id<FDMultipartFormData> formData) {
            NSString *rfc3339TimeStamp  = [FDDateUtil getRFC3339TimeStamp];
            NSString *dubugDataFileName = [NSString stringWithFormat:@"Debug Data %@.txt",rfc3339TimeStamp];
            [formData appendPartWithFileData:data name:MOBIHELP_API_DEBUG_DATA_FIELD fileName:dubugDataFileName mimeType:@"application/octet-stream"];
            if (ticketContent.imageData) {
                [formData appendPartWithFileData:ticketContent.imageData name:MOBIHELP_API_TICKET_ATTACHMENT_DATA_FIELD fileName:@"Image" mimeType:@"image/jpeg"];
            }
        } success:^(NSURLSessionDataTask *task, id responseObject) {
            completion(responseObject,nil);
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            completion(nil, error);
        }];
    }];
    return task;
}

-(NSURLSessionDataTask *)fetchAllTicketsWithParams:(NSDictionary *)params completion:(void(^)(NSArray *tickets, NSError *error))completion{
    NSString *deviceUUID = [self.secureStore objectForKey:MOBIHELP_DEFAULTS_DEVICE_UUID];
    NSString *ticketURL  = [NSString stringWithFormat:MOBIHELP_API_GET_ALL_TICKETS,deviceUUID];
    NSString *apiKey     = [self.secureStore objectForKey:MOBIHELP_DEFAULTS_API_KEY];
    NSString *appKey     = [self.secureStore objectForKey:MOBIHELP_DEFAULTS_APP_KEY];
    [self.networkManager.sessionManager.requestSerializer setAuthorizationHeaderFieldWithUsername:apiKey password:@"x"];
    [self.networkManager.sessionManager.requestSerializer setValue:appKey forHTTPHeaderField:@"X-FD-Mobihelp-AppId"];
    return [self.networkManager GET:ticketURL parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        [self.secureStore setObject:[NSDate date] forKey:MOBIHELP_DEFAULTS_TICKETS_LAST_UPDATED_TIME];
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil, error);
    }];
}

#pragma mark - Note creation and fetching

-(NSURLSessionDataTask *)createNoteWithContent:(FDNoteContent *)content andParam:(NSDictionary *)params completion:(void (^)(NSDictionary *, NSError *))completion{
    NSString *noteURL = [NSString stringWithFormat:MOBIHELP_API_CREATE_NEW_NOTE_WITH_TICKET_ID,content.ticketID];
    NSData *attachmentData  = content.imageData;
    NSString *apiKey = [self.secureStore objectForKey:MOBIHELP_DEFAULTS_API_KEY];
    [self.networkManager.sessionManager.requestSerializer setAuthorizationHeaderFieldWithUsername:apiKey password:@"x"];
    [self.networkManager POST:noteURL parameters:params constructingBodyWithBlock:^(id<FDMultipartFormData> formData) {
        NSString *imageName = [NSString stringWithFormat:@"Image-%@",content.ticketID];
        if (attachmentData) {
            [formData appendPartWithFileData:attachmentData name:MOBIHELP_API_NOTE_ATTACHMENT_DATA_FIELD fileName:imageName mimeType:@"image/jpeg"];
        }
    } success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
    return nil;
}

-(NSURLSessionDataTask *)fetchAllNotesforTicketID:(NSNumber *)ticketID withParams:(NSDictionary *)params completion:(void(^)(NSDictionary *fetchedNotes, NSError *error))completion{
    NSString *deviceUUID = [self.secureStore objectForKey:MOBIHELP_DEFAULTS_DEVICE_UUID];
    NSString *ticketURL = [NSString stringWithFormat:MOBIHELP_API_GET_TICKET_WITH_ID,ticketID,deviceUUID];
    NSString *apiKey = [self.secureStore objectForKey:MOBIHELP_DEFAULTS_API_KEY];
    [self.networkManager.sessionManager.requestSerializer setAuthorizationHeaderFieldWithUsername:apiKey password:@"x"];
    return [self.networkManager GET:ticketURL parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil, error);
    }];
}

-(NSURLSessionDataTask *)closeTicketWithID:(NSNumber *)ticketID completion:(void (^)(NSDictionary *, NSError *))completion{
    NSString *URL  = [NSString stringWithFormat:MOBIHELP_API_CLOSE_TICKET_WITH_ID,ticketID];
    return [self.networkManager POST:URL parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject, nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil, error);
    }];
}

@end