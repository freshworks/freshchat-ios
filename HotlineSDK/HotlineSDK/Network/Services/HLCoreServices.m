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
#import "FDMemLogger.h"

@implementation HLCoreServices

-(NSURLSessionDataTask *)updateSDKBuildNumber:(NSString *)SDKVersion{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FDUtilities getUserAlias];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_UPDATE_SDK_BUILD_NUMBER_PATH,appID,userAlias];
    NSString *clientVersion = [NSString stringWithFormat:@"clientVersion=%@",SDKVersion];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithMethod:HTTP_METHOD_PUT];
    [request setRelativePath:path andURLParams:@[appKey,clientVersion,@"clientType=2"]];
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

-(NSDictionary *)getUserInfo{
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    NSString *adId = [FDUtilities getAdID];
    NSString *userAlias = [FDUtilities getUserAlias];
    NSDictionary *deviceProps = [FDUtilities deviceInfoProperties];
    
    if (userAlias) {
        userInfo[@"alias"] = userAlias;
    }else{
        if([[FDSecureStore sharedInstance] checkItemWithKey:HOTLINE_DEFAULTS_APP_ID]){
            // If appID is present then something is terribly wrong. Call the doctor
            FDMemLogger *memLogger = [[FDMemLogger alloc]init];
            [memLogger addMessage:@"Skipping user registration" withMethodName:NSStringFromSelector(_cmd)];
            if(!userAlias){
                [memLogger addErrorInfo:@{ @"Reason": @"userAlias is nil"}];
            }
            [memLogger upload];
        }
        return nil;
    }

    if (deviceProps) {
        userInfo[@"meta"] = deviceProps;
    }
    
    if (adId && adId.length > 0) {
        userInfo[@"adId"] = adId;
    }
    
    return  @{ @"user" : userInfo };
}

-(NSURLSessionDataTask *)registerUser:(void (^)(NSError *error))handler{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_USER_REGISTRATION_PATH,appID];
    
    NSDictionary *userInfo = [self getUserInfo];
    
    if (!userInfo) {
        return nil;
    }
    
    NSError *error = nil;
    NSData *userData = [NSJSONSerialization dataWithJSONObject:userInfo options:NSJSONWritingPrettyPrinted error:&error];
    
    if (error) {
        FDLog(@"Error while serializing user information");
    }
    
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithMethod:HTTP_METHOD_POST];
    [request setBody:userData];
    [request setRelativePath:path andURLParams:@[appKey]];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
        NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
        if (!error) {
            
            FDLog(@" *** User registration status *** ");
            
            if (statusCode == 201 || statusCode == 304) {
                
                if (statusCode == 201) FDLog(@"New user created successfully");
                
                if (statusCode == 304) FDLog(@"Existing user is mapped successfully");
                
                [[FDSecureStore sharedInstance] setBoolValue:YES forKey:HOTLINE_DEFAULTS_IS_USER_REGISTERED];
                
                if (handler) handler(nil);
                
            }else{
                FDLog(@"Failed with wrong status code");
                if (handler) handler([NSError new]);
            }
            
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
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithMethod:HTTP_METHOD_PUT];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_DEVICE_REGISTRATION_PATH,appID,userAlias];
    NSString *notificationID = [NSString stringWithFormat:@"notification_id=%@",pushToken];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
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
    
    static BOOL IN_PROGRESS = NO;
    
    if(IN_PROGRESS){
        return;
    }
    
    IN_PROGRESS = YES ;
    
    [[KonotorDataManager sharedInstance].mainObjectContext performBlock:^{
        
        if (![FDUtilities isUserRegistered]) {
            IN_PROGRESS = NO;
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
            IN_PROGRESS = NO;
            return;
        }
        
        [self updateUserProperties:info handler:^(NSError *error) {
            if (!error) {
                [[KonotorDataManager sharedInstance].mainObjectContext performBlock:^{
                    for (int i=0; i<unuploadedProperties.count; i++) {
                        KonotorCustomProperty *property = unuploadedProperties[i];
                        if (property.managedObjectContext != nil) {
                            property.uploadStatus = @1;
                        }else{
                            FDLog(@"Trying to access deleted meta object - Ignoring");
                        }
                    }
                    [[KonotorDataManager sharedInstance]save];
               
                    IN_PROGRESS = NO;
                    NSArray *remaining = [KonotorCustomProperty getUnuploadedProperties];
                    if (remaining.count > 0) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [self uploadUnuploadedProperties];
                        });
                    }
                }];
            }
            IN_PROGRESS = NO;
        }];
    }];
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
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithMethod:HTTP_METHOD_PUT];
    [request setBody:encodedInfo];
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

+(NSURLSessionDataTask *)DAUCall:(void (^)(NSError *))completion{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FDUtilities getUserAlias];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_DAU_PATH,appID,userAlias];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithMethod:HTTP_METHOD_PUT];
    [request setRelativePath:path andURLParams:@[appKey]];
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
        if (!error) {
            FDLog(@"DAU call made");
        }else{
            FDLog(@"Could not make DAU call %@", error);
            FDLog(@"Response : %@", responseInfo.response);
        }
        if(completion){
            completion(error);
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
    
    
    NSString *conversationAlias = message.belongsToConversation.conversationAlias;
    
    if (conversationAlias && [conversationAlias longLongValue] > 0) {
        info[@"conversationId"] = message.belongsToConversation.conversationAlias;
    }else{
        FDLog(@"*** Do not update read reciept for marketing campaign message ***");
        return nil;
    }
    
    if (message.belongsToChannel.channelID) {
        info[@"channelId"] = message.belongsToChannel.channelID;
    }
    
    if (message.createdMillis) {
        info[@"readUpto"] = message.createdMillis;
    }
    
    NSData *userData = [NSJSONSerialization dataWithJSONObject:info  options:NSJSONWritingPrettyPrinted error:nil];
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithMethod:HTTP_METHOD_POST];
    [request setBody:userData];
    [request setRelativePath:path andURLParams:@[appKey]];
    
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
        if (!error) {
            FDLog(@"*** Read reciept : Updated Successfully ***")
        }else{
            FDLog(@"** Read reciept : failed *** %@ ", error);
            FDLog(@"Response : %@", responseInfo.response);
        }
    }];
    return task;
}

+(void)sendLatestUserActivity:(HLChannel *)channel{
    NSManagedObjectContext *context = [[KonotorDataManager sharedInstance]mainObjectContext];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_MESSAGE_ENTITY];
    
    NSPredicate *queryChannelAndRead = [NSPredicate predicateWithFormat:@"messageRead == 1 AND belongsToChannel == %@", channel];
    NSPredicate *queryType = [NSPredicate predicateWithFormat:@"isWelcomeMessage == 0 AND messageUserId != %@", USER_TYPE_MOBILE];
    request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[queryChannelAndRead, queryType]];
    NSArray *messages = [context executeFetchRequest:request error:nil];
    
    NSSortDescriptor *sortDesc =[[NSSortDescriptor alloc] initWithKey:@"createdMillis" ascending:NO];
    KonotorMessage *latestMessage = [messages sortedArrayUsingDescriptors:@[sortDesc]].firstObject;
    if(latestMessage){
        [HLCoreServices registerUserConversationActivity:latestMessage];
    }
}

+(NSURLSessionDataTask *)trackUninstallForUser:(NSDictionary *) userInfo withCompletion:(void (^)(NSError *))completion{
    NSString *appID = userInfo[@"appId"];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",userInfo[@"appKey"]];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_UNINSTALLED_PATH,appID,userInfo[@"userAlias"]];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:HOTLINE_USER_DOMAIN,userInfo[@"domain"]]];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:url andMethod:HTTP_METHOD_PUT];
    [request setRelativePath:path andURLParams:@[appKey]];
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
        if (!error) {
            NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
            if(statusCode == 202 || statusCode == 200){
                FDLog(@"Previous user marked as uninstalled");
            }
        }else{
            NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
            if(statusCode == 404 ){
                // user does not belong to this app ( or domain )
                error = nil; // ignore error
            }
            else {
                FDLog(@"User uninstall call failed %@", error);
                FDLog(@"Response : %@", responseInfo.response);
            }
        }
        if(completion){
            completion(error);
        }
    }];
    return task;
}

@end
