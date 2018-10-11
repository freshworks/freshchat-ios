//
//  HLCoreServices.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 03/01/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FCCoreServices.h"
#import "FCAPIClient.h"
#import "FCServiceRequest.h"
#import "FCSecureStore.h"
#import "FCUsers.h"
#import "FCMacros.h"
#import "FCUtilities.h"
#import "FCDataManager.h"
#import "FCConstants.h"
#import "FCResponseInfo.h"
#import "FCUserProperties.h"
#import "FCMemLogger.h"
#import "FCLocaleUtil.h"
#import "FCLocaleConstants.h"
#import "FCRemoteConfig.h"
#import "FCUserUtil.h"
#import "FCLocalNotification.h"
#import "FCVotingManager.h"
#import "FCJWTUtilities.h"


@interface Freshchat ()

-(void)registerDeviceToken;
-(NSDictionary *) getPreviousUserConfig;
-(void)storePreviousUser:(NSDictionary *) previousUserInfo inStore:(FCSecureStore *)secureStore;

@end

@interface FCUsers ()

+(void) removeUserInfo;

@end


@implementation FCCoreServices

-(NSURLSessionDataTask *)updateSDKBuildNumber:(NSString *)SDKVersion{
    if(![FCUserUtil isUserRegistered]){
        return nil;
    }
    FCSecureStore *store = [FCSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FCUtilities currentUserAlias];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_UPDATE_SDK_BUILD_NUMBER_PATH,appID,userAlias];
    NSString *clientVersion = [NSString stringWithFormat:@"clientVersion=%@",SDKVersion];
    FCServiceRequest *request = [[FCServiceRequest alloc]initWithMethod:HTTP_METHOD_PUT];
    [request setRelativePath:path andURLParams:@[appKey,clientVersion,@"clientType=2"]];
    FCAPIClient *apiClient = [FCAPIClient sharedInstance];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FCResponseInfo *responseInfo, NSError *error) {
        if (!error) {
            [store setObject:FRESHCHAT_SDK_BUILD_NUMBER forKey:HOTLINE_DEFAULTS_SDK_BUILD_NUMBER];
            FDLog(@"SDK build number updated to server");
        }else{
            FDLog(@"SDK build number could not be updated %@", error);
            FDLog(@"Response : %@", responseInfo.response);
        }
    }];
    return task;
}

-(NSMutableDictionary *)getUserInfo:(NSString *) userAlias{
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    NSString *adId = [FCUtilities getAdID];
    NSDictionary *deviceProps = [FCUtilities deviceInfoProperties];
    
    if (userAlias) {
        userInfo[@"alias"] = userAlias;
    }else{
        if([[FCSecureStore sharedInstance] checkItemWithKey:HOTLINE_DEFAULTS_APP_ID]){
            // If appID is present then something is terribly wrong. Call the doctor
            FCMemLogger *memLogger = [[FCMemLogger alloc]init];
            [memLogger addMessage:@"Skipping user registration" withMethodName:NSStringFromSelector(_cmd)];
            if(!userAlias){
                [memLogger addErrorInfo:@{ @"Reason": @"userAlias is nil"}];
            }
            [memLogger upload];
        }
        return nil;
    }
    
    if (deviceProps) {
        userInfo[@"deviceIosMeta"] = deviceProps;
    }
    
    if (adId && adId.length > 0) {
        userInfo[@"adId"] = adId;
    }
    
    return userInfo;
}

-(NSURLSessionDataTask *)registerUser:(void (^)(NSError *error))handler{
    FCSecureStore *store = [FCSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_USER_REGISTRATION_PATH,appID];
    
    NSMutableDictionary *userInfo = [self getUserInfo:[FCUtilities getUserAliasWithCreate]];
    NSArray *userProperties = [FCCoreServices updatePropertiesTo:userInfo];
    
    if (!userInfo) {
        return nil;
    }
    
    NSError *error = nil;
    
    NSData *userData = [NSJSONSerialization dataWithJSONObject:@{ @"user" : userInfo } options:NSJSONWritingPrettyPrinted error:&error];
    
    if (error) {
        FDLog(@"Error while serializing user information");
    }
    
    FCAPIClient *apiClient = [FCAPIClient sharedInstance];
    FCServiceRequest *request = [[FCServiceRequest alloc]initWithMethod:HTTP_METHOD_POST];
    [request setBody:userData];
    [request setRelativePath:path andURLParams:@[appKey]];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FCResponseInfo *responseInfo, NSError *error) {
        NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
        if (!error) {
            
            FDLog(@"*** User registration status ***");
            
            if (statusCode == 201 || statusCode == 304) {
                
                if (statusCode == 201) FDLog(@"New user created successfully");
                
                if (statusCode == 304) FDLog(@"Existing user is mapped successfully");
                
                ALog(@"User registered - %@", [userInfo valueForKeyPath:@"user.alias"]);
                
                [[FCSecureStore sharedInstance] setBoolValue:YES forKey:HOTLINE_DEFAULTS_IS_USER_REGISTERED];
                [FCCoreServices setAsUploadedTo:userProperties withCompletion:nil];
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

+ (NSArray *) updatePropertiesTo: (NSMutableDictionary *) userInfo {
    NSArray *propertiesToUpload = [FCUserProperties getUnuploadedProperties];
    if (propertiesToUpload.count > 0) {
        NSMutableDictionary *metaInfo = [NSMutableDictionary new];
        for (int i=0; i<propertiesToUpload.count; i++) {
            FCUserProperties *property = propertiesToUpload[i];
            if (property.key) {
                if (property.isUserProperty) {
                    userInfo[property.key] = property.value;
                }else{
                    metaInfo[property.key] = property.value;
                }
            }
        }
        userInfo[@"meta"] = metaInfo;
    }
    return propertiesToUpload;
}

+(void) setAsUploadedTo:(NSArray *) properties withCompletion:(void (^)())completion {
    [[FCDataManager sharedInstance].mainObjectContext performBlock:^{
        for (int i=0; i<properties.count; i++) {
            FCUserProperties *property = properties[i];
            if (property.managedObjectContext != nil) {
                property.uploadStatus = @1;
            } else {
                FDLog(@"Trying to access deleted meta object - Ignoring");
            }
        }
        [[FCDataManager sharedInstance]save];
        if(completion){
            completion();
        }
    }];
}
 
-(NSURLSessionDataTask *)registerAppWithToken:(NSString *)pushToken forUser:(NSString *)userAlias handler:(void (^)(NSError *))handler{
    if (![FCUserUtil isUserRegistered] || !pushToken) return nil;
    FCAPIClient *apiClient = [FCAPIClient sharedInstance];
    FCSecureStore *store = [FCSecureStore sharedInstance];
    FCServiceRequest *request = [[FCServiceRequest alloc]initWithMethod:HTTP_METHOD_PUT];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_DEVICE_REGISTRATION_PATH,appID,userAlias];
    NSString *notificationID = [NSString stringWithFormat:@"notification_id=%@",pushToken];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    [request setRelativePath:path andURLParams:@[@"notification_type=2", notificationID, appKey]];

    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FCResponseInfo *responseInfo, NSError *error) {
        if (!error) {
            [store setBoolValue:YES forKey:HOTLINE_DEFAULTS_IS_DEVICE_TOKEN_REGISTERED];
            ALog(@"Push token registered : %@", pushToken);
        }else{
            FDLog(@"Could not register app :%@", error);
            FDLog(@"Response : %@", responseInfo.response);
        }
    }];
    return task;
}

+(void)uploadUnuploadedProperties {
    [FCCoreServices uploadUnuploadedPropertiesWithForceUpdate:false];
}

+(void)uploadUnuploadedPropertiesWithForceUpdate:(BOOL) forceUpdate {
    
    static BOOL IN_PROGRESS = NO;
    
    if(IN_PROGRESS){
        return;
    }
    
    if (![FCUserUtil isUserRegistered]) {
        return; // this is required outside and inside the block
        // double entrant lock
    }
    
    IN_PROGRESS = YES ;
    
    [[FCDataManager sharedInstance].mainObjectContext performBlock:^{
        if (![FCUserUtil isUserRegistered] ) { //If the user 
            IN_PROGRESS = NO;
            return;
        }
        
        NSMutableDictionary *info = [NSMutableDictionary new];
        NSMutableDictionary *userInfo = [NSMutableDictionary new];
        
        
        NSArray *userProperties = [FCCoreServices updatePropertiesTo:userInfo];
        if (userProperties.count > 0 || forceUpdate) {
            userInfo[@"alias"] = [FCUtilities currentUserAlias];
            NSDictionary *deviceProps = [FCUtilities deviceInfoProperties];
            if (deviceProps) {
                userInfo[@"deviceIosMeta"] = deviceProps;
            }
            if([FreshchatUser sharedInstance].externalID != nil) {
                userInfo[@"identifier"] = [FreshchatUser sharedInstance].externalID;
            }
            info[@"user"] = userInfo;
        }else{
            IN_PROGRESS = NO;
        }
        
        if ([info count] == 0) {
            IN_PROGRESS = NO;
            return;
        }
        
        [self updateUserProperties:info handler:^(NSError *error) {
            if (!error) {
                [FCCoreServices setAsUploadedTo:userProperties withCompletion:^{
                    IN_PROGRESS = NO;
                    NSArray *remaining = [FCUserProperties getUnuploadedProperties];
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
    if(![FCUserUtil isUserRegistered]) {
        return nil; // This should never happen .. just a safety check
    }
    FCAPIClient *apiClient = [FCAPIClient sharedInstance];
    FCSecureStore *store = [FCSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FCUtilities currentUserAlias];
    if (!userAlias) return nil;
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_USER_PROPERTIES_PATH,appID,userAlias];
    NSData *encodedInfo = [NSJSONSerialization dataWithJSONObject:info  options:NSJSONWritingPrettyPrinted error:nil];
    FCServiceRequest *request = [[FCServiceRequest alloc]initWithMethod:HTTP_METHOD_PUT];
    [request setBody:encodedInfo];
    [request setRelativePath:path andURLParams:@[appKey]];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FCResponseInfo *responseInfo, NSError *error) {
        if (!error) {
            NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
            if(statusCode == 200){
                FDLog(@"Pushed properties to server %@", info);
                NSDictionary *response = responseInfo.responseAsDictionary;
                [FCUtilities updateUserWithExternalID:[response objectForKey:@"identifier"] withRestoreID:[response objectForKey:@"restoreId"]];
                if (handler) handler(nil);
            }
        }else{
            if (handler) handler(error);
            FDLog(@"Could not update user properties %@", error);
            FDLog(@"Response : %@", responseInfo.response);
        }
    }];
    return task;
}

+(NSURLSessionDataTask *)performDAUCall{
    if([FCUtilities canMakeDAUCall]){
        [[FCSecureStore sharedInstance] setObject:[NSDate date] forKey:HOTLINE_DEFAULTS_DAU_LAST_UPDATED_TIME];
        FCSecureStore *store = [FCSecureStore sharedInstance];
        NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
        NSString *userAlias = [[FCUtilities currentUserAlias] length] ? [FCUtilities currentUserAlias] : [FCUtilities getUserAliasWithCreate];
        NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
        NSString *path = [NSString stringWithFormat:HOTLINE_API_DAU_PATH,appID,userAlias];
        FCServiceRequest *request = [[FCServiceRequest alloc]initWithMethod:HTTP_METHOD_PUT];
        [request setRelativePath:path andURLParams:@[appKey,@"source=MOBILE"]];
        FCAPIClient *apiClient = [FCAPIClient sharedInstance];
        @try {
            NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FCResponseInfo *responseInfo, NSError *error) {
                if (!error) {
                    NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
                    if(statusCode == 200){
                        FDLog(@"**** DAU call made ****");
                    }
                }else{
                    FDLog(@"Could not make DAU call %@", error);
                    FDLog(@"Response : %@", responseInfo.response);
                    [[FCSecureStore sharedInstance] removeObjectWithKey:HOTLINE_DEFAULTS_DAU_LAST_UPDATED_TIME];
                }
            }];
            
            return task;
        }
        @catch (NSException *exception) {
            [[FCSecureStore sharedInstance] removeObjectWithKey:HOTLINE_DEFAULTS_DAU_LAST_UPDATED_TIME];
            FDLog(@"Activity request failed due to an error %@", exception.description);
        }
    }
    return nil;
}

+(NSURLSessionDataTask *)performSessionCall{
    FCSecureStore *store = [FCSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FCUtilities currentUserAlias];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_SESSION_PATH,appID,userAlias];
    FCServiceRequest *request = [[FCServiceRequest alloc]initWithMethod:HTTP_METHOD_POST];
    [request setRelativePath:path andURLParams:@[appKey]];
    FCAPIClient *apiClient = [FCAPIClient sharedInstance];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FCResponseInfo *responseInfo, NSError *error) {
        if (!error) {
            NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
            if(statusCode == 200){
                FDLog(@"**** Session call made ****");
            }
        }else{
            FDLog(@"Could not make Session call %@", error);
            FDLog(@"Response : %@", responseInfo.response);
        }
    }];
    return task;
}

+(NSURLSessionDataTask *)performHeartbeatCall{
    FCSecureStore *store = [FCSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FCUtilities currentUserAlias];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_HEARTBEAT_PATH,appID,userAlias];
    FCServiceRequest *request = [[FCServiceRequest alloc]initWithMethod:HTTP_METHOD_POST];
    [request setRelativePath:path andURLParams:@[appKey]];
    FCAPIClient *apiClient = [FCAPIClient sharedInstance];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FCResponseInfo *responseInfo, NSError *error) {
        if (!error) {
            NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
            if(statusCode == 200){
                FDLog(@"**** heartbeat call done ****");
            }
        }else{
            FDLog(@"Could not make Session call %@", error);
            FDLog(@"Response : %@", responseInfo.response);
        }
    }];
    return task;
}

+(NSURLSessionDataTask *)registerUserConversationActivity :(FCMessages *)message{
    FCSecureStore *store = [FCSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FCUtilities currentUserAlias];
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
    FCAPIClient *apiClient = [FCAPIClient sharedInstance];
    FCServiceRequest *request = [[FCServiceRequest alloc]initWithMethod:HTTP_METHOD_POST];
    [request setBody:userData];
    [request setRelativePath:path andURLParams:@[appKey]];
    
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FCResponseInfo *responseInfo, NSError *error) {
        if (!error) {
            FDLog(@"*** Read reciept : Updated Successfully ***")
        }else{
            FDLog(@"** Read reciept : failed *** %@ ", error);
            FDLog(@"Response : %@", responseInfo.response);
        }
    }];
    return task;
}

+(void)sendLatestUserActivity:(FCChannels *)channel{
    if (!([FCRemoteConfig sharedInstance].accountActive && [FCUserUtil isUserRegistered])){
        return;
    }
    NSManagedObjectContext *context = [[FCDataManager sharedInstance]mainObjectContext];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_MESSAGES_ENTITY];
    
    NSPredicate *queryChannelAndRead = [NSPredicate predicateWithFormat:@"isRead == 1 AND belongsToChannel == %@", channel];
    NSPredicate *queryType = [NSPredicate predicateWithFormat:@"isWelcomeMessage == 0 AND messageUserAlias != %@", USER_TYPE_MOBILE];
    request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[queryChannelAndRead, queryType]];
    NSArray *messages = [context executeFetchRequest:request error:nil];
    
    NSSortDescriptor *sortDesc =[[NSSortDescriptor alloc] initWithKey:@"createdMillis" ascending:NO];
    FCMessages *latestMessage = [messages sortedArrayUsingDescriptors:@[sortDesc]].firstObject;
    if(latestMessage){
        //update read activity
        if( [FCRemoteConfig sharedInstance].enabledFeatures.inboxEnabled && [FCRemoteConfig sharedInstance].accountActive ){
            [FCCoreServices registerUserConversationActivity:latestMessage];
        }
    }
}

+(NSURLSessionDataTask *)trackUninstallForUser:(NSDictionary *) userInfo withCompletion:(void (^)(NSError *))completion{
    NSString *appID = userInfo[@"appId"];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",userInfo[@"appKey"]];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_UNINSTALLED_PATH,appID,userInfo[@"userAlias"]];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:HOTLINE_USER_DOMAIN,userInfo[@"domain"]]];
    FCServiceRequest *request = [[FCServiceRequest alloc]initWithBaseURL:url andMethod:HTTP_METHOD_PUT];
    [request setRelativePath:path andURLParams:@[appKey]];
    FCAPIClient *apiClient = [FCAPIClient sharedInstance];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FCResponseInfo *responseInfo, NSError *error) {
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

+(NSURLSessionDataTask *)fetchRemoteConfig{
    
    FCSecureStore *store = [FCSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    NSString *path = [NSString stringWithFormat:FRESHCHAT_API_REMOTE_CONFIG_PATH,appID];
    
    NSURL *configBaseUrl = [NSURL URLWithString:[NSString stringWithFormat:HOTLINE_USER_DOMAIN,[NSString stringWithFormat:FRESHCHAT_API_REMOTE_CONFIG_PREFIX,[store objectForKey:HOTLINE_DEFAULTS_DOMAIN]]]];
    FCServiceRequest *request = [[FCServiceRequest alloc]initWithBaseURL:configBaseUrl andMethod:HTTP_METHOD_GET];
    
    [request setRelativePath:path andURLParams:@[appKey]];
    FCAPIClient *apiClient = [FCAPIClient sharedInstance];
    
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FCResponseInfo *responseInfo, NSError *error) {
        NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
        if(!error && statusCode == 200) {
            NSDictionary *configDict = responseInfo.responseAsDictionary;
            [FCUserDefaults setObject:[NSDate date] forKey:CONFIG_RC_LAST_API_FETCH_INTERVAL_TIME];
            [[FCRemoteConfig sharedInstance] updateRemoteConfig:configDict];
        }
        else {
            FDLog(@"User remote config fetch call failed %@", error);
        }
    }];
    return task;
}

+(NSURLSessionDataTask *)fetchTypicalReply:(void (^)(FCResponseInfo *responseInfo, NSError *error))handler {
    FCSecureStore *store = [FCSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_TYPLICAL_REPLY,appID];
    FCAPIClient *apiClient = [FCAPIClient sharedInstance];
    FCServiceRequest *request = [[FCServiceRequest alloc]initWithMethod:HTTP_METHOD_GET];
    [request setRelativePath:path andURLParams:@[appKey]];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FCResponseInfo *responseInfo, NSError *error) {
        NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
        if (!error) {
            if (statusCode == 200) {
                if (handler) handler(responseInfo,nil);
            } else{
                if (handler) handler(responseInfo,[NSError new]);
            }
        }
        if (handler) handler(responseInfo,error);
    }];
    return task;
}

+(NSURLSessionDataTask *)restoreUserWithJwtToken:(NSString *)token withCompletion:(void (^)(NSError *))completion{
    
    FCSecureStore *store = [FCSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    //NSString *userAlias = [FCUtilities currentUserAlias];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    NSString *path = [NSString stringWithFormat:FRESHCHAT_USER_RESTORE_WITH_JWT_PATH,appID];
    
    NSError *error = nil;
    NSData *userData = [NSJSONSerialization dataWithJSONObject:@{ @"jwtAuthToken" : token } options:NSJSONWritingPrettyPrinted error:&error];
    
    FCServiceRequest *request = [[FCServiceRequest alloc]initWithMethod:HTTP_METHOD_POST];
    [request setBody:userData];
    [request setRelativePath:path andURLParams:@[appKey]];
    FCAPIClient *apiClient = [FCAPIClient sharedInstance];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FCResponseInfo *responseInfo, NSError *error) {
        NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
        NSDictionary *response = responseInfo.responseAsDictionary;
        apiClient.FC_IS_USER_OR_ACCOUNT_DELETED = NO;
        if (statusCode == 200) { //If the user is found
            if (![[FCUtilities currentUserAlias] isEqual:response[@"alias"]]) {
                [FCUtilities updateUserWithData:response];
                [FCUserUtil setUserMessageInitiated];
                [[FCSecureStore sharedInstance] setBoolValue:YES forKey:HOTLINE_DEFAULTS_IS_USER_REGISTERED];
                [FCUtilities initiatePendingTasks];
                //Authenticated User
            }
        } else {
            //If the user is not found
        }
        
        if(completion){
            completion(error);
        }
    }];
    return task;
}

+(NSURLSessionDataTask *)restoreUserWithExtId:(NSString *)extId restoreId:(NSString *)restoreIdVal withCompletion:(void (^)(NSError *))completion{
    FCSecureStore *store = [FCSecureStore sharedInstance];
    NSMutableArray *params = [[NSMutableArray alloc] init];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    [params addObject:[NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]]];
    if(extId.length >0){
        [params addObject:[NSString stringWithFormat:@"externalId=%@", [FCStringUtil base64EncodedStringFromString:extId]]];
    } else {
        return nil;
    }
    if(restoreIdVal.length > 0){
        [params addObject:[NSString stringWithFormat:@"restoreId=%@",restoreIdVal]];
    } else {
        return nil;
    }
    NSString *path = [NSString stringWithFormat:FRESHCHAT_USER_RESTORE_PATH,appID];
    FCAPIClient *apiClient = [FCAPIClient sharedInstance];
    FCServiceRequest *request = [[FCServiceRequest alloc]initWithMethod:HTTP_METHOD_GET];
    [request setRelativePath:path andURLParams:params];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FCResponseInfo *responseInfo, NSError *error) {
        NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
        NSDictionary *response = responseInfo.responseAsDictionary;
        apiClient.FC_IS_USER_OR_ACCOUNT_DELETED = NO;
        if (statusCode == 200) { //If the user is found
            if(response[@"restoreId"] && response[@"identifier"]) {
                if (![[FCUtilities currentUserAlias] isEqual:response[@"alias"]]) {
                    [FCUtilities updateUserWithData:response];
                    [FCUserUtil setUserMessageInitiated];
                    [[FCSecureStore sharedInstance] setBoolValue:YES forKey:HOTLINE_DEFAULTS_IS_USER_REGISTERED];
                    [FCUtilities updateUserWithExternalID:response[@"identifier"] withRestoreID:response[@"restoreId"]];
                    [FCUtilities initiatePendingTasks];
                }
            }
        } else { //If the user is not found
            FreshchatUser* oldUser = [FreshchatUser sharedInstance];
            oldUser.externalID = extId;
            oldUser.restoreID = nil;
            [[Freshchat sharedInstance] setUser:oldUser];
            [FCUtilities resetAlias];
            [FCLocalNotification post:FRESHCHAT_USER_RESTORE_ID_GENERATED info:@{}];
            [FCUtilities initiatePendingTasks];
        }
        
        if(completion){
            completion(error);
        }
    }];
    return task;
}

+(void) resetUserData:(void (^)())completion {    
    [FreshchatUser sharedInstance].isRestoring = true;
    [FCLocalNotification post:FRESHCHAT_USER_RESTORE_STATE info:@{@"state":@0}];
    [[FCDataManager sharedInstance] clearUserExceptTags:^(NSError *error) {
        FCSecureStore *store = [FCSecureStore sharedInstance];
        // Store the user again to send uninstall api again
        NSDictionary *previousUser = [[Freshchat sharedInstance] getPreviousUserConfig];
        BOOL isUserRegistered = [FCUserUtil isUserRegistered];
        if(previousUser && isUserRegistered) {
            [[Freshchat sharedInstance] storePreviousUser:previousUser inStore:store];
        } else {
            [[Freshchat sharedInstance] storePreviousUser:nil inStore:store];
        }
        // Clear the Channel & Coversation call to fetch again.
        [store removeObjectWithKey:HOTLINE_DEFAULTS_VOTED_ARTICLES];        
        [store removeObjectWithKey:FC_CHANNELS_LAST_MODIFIED_AT];
        [store removeObjectWithKey:FC_CONVERSATIONS_LAST_MODIFIED_AT];//Absolute after v1.5.0 : Can be removed in later versions of SDK
        [store removeObjectWithKey:FC_CONVERSATIONS_LAST_MODIFIED_AT_V2];
        [store removeObjectWithKey:FC_CHANNELS_LAST_REQUESTED_TIME];
        [store removeObjectWithKey:FC_CONVERSATIONS_LAST_REQUESTED_TIME];
        
        // Clear the token again to register again
        [store removeObjectWithKey:HOTLINE_DEFAULTS_IS_DEVICE_TOKEN_REGISTERED];
        [store removeObjectWithKey:HOTLINE_DEFAULTS_DAU_LAST_UPDATED_TIME];
        [FCUserDefaults removeObjectForKey:FRESHCHAT_DEFAULTS_SESSION_UPDATED_TIME];
        [[FCVotingManager sharedInstance].votedArticlesDictionary removeAllObjects];
        [FCUsers removeUserInfo];
        if(completion){
            completion(error);
        }
    }];
}

@end
