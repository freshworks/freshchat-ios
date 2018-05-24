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
#import "KonotorUser.h"
#import "HLMacros.h"
#import "FDUtilities.h"
#import "KonotorDataManager.h"
#import "HLConstants.h"
#import "FDResponseInfo.h"
#import "KonotorCustomProperty.h"
#import "FDMemLogger.h"
#import "FDLocaleUtil.h"
#import "FDConstants.h"
#import "FCRemoteConfig.h"
#import "HLUser.h"
#import "FDLocalNotification.h"
#import "FDVotingManager.h"


@interface Freshchat ()

-(void)performPendingTasks;
-(void)registerDeviceToken;
-(NSDictionary *) getPreviousUserConfig;
-(void)storePreviousUser:(NSDictionary *) previousUserInfo inStore:(FDSecureStore *)secureStore;

@end

@interface KonotorUser ()

+(void) removeUserInfo;

@end


@implementation HLCoreServices

-(NSURLSessionDataTask *)updateSDKBuildNumber:(NSString *)SDKVersion{
    if(![HLUser isUserRegistered]){
        return nil;
    }
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FDUtilities currentUserAlias];
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

-(NSDictionary *)getUserInfo:(NSString *) userAlias{
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    NSString *adId = [FDUtilities getAdID];
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
        userInfo[@"deviceIosMeta"] = deviceProps;
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
    
    NSDictionary *userInfo = [self getUserInfo:[FDUtilities getUserAliasWithCreate]];
    
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
            
            FDLog(@"*** User registration status ***");
            
            if (statusCode == 201 || statusCode == 304) {
                
                if (statusCode == 201) FDLog(@"New user created successfully");
                
                if (statusCode == 304) FDLog(@"Existing user is mapped successfully");
                
                ALog(@"User registered - %@", [userInfo valueForKeyPath:@"user.alias"]);
                
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
    if (![HLUser isUserRegistered] || !pushToken) return nil;
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
            ALog(@"Push token registered : %@", pushToken);
        }else{
            FDLog(@"Could not register app :%@", error);
            FDLog(@"Response : %@", responseInfo.response);
        }
    }];
    return task;
}

+(void)uploadUnuploadedProperties {
    [HLCoreServices uploadUnuploadedPropertiesWithForceUpdate:false];
}

+(void)uploadUnuploadedPropertiesWithForceUpdate:(BOOL) forceUpdate {
    
    static BOOL IN_PROGRESS = NO;
    
    if(IN_PROGRESS){
        return;
    }
    
    if (![HLUser isUserRegistered]) {
        return; // this is required outside and inside the block
        // double entrant lock
    }
    
    IN_PROGRESS = YES ;
    
    [[KonotorDataManager sharedInstance].mainObjectContext performBlock:^{
        if (![HLUser isUserRegistered] ) { //If the user 
            IN_PROGRESS = NO;
            return;
        }
        
        NSMutableDictionary *info = [NSMutableDictionary new];
        NSMutableDictionary *userInfo = [NSMutableDictionary new];
        
        NSArray *unuploadedProperties = [KonotorCustomProperty getUnuploadedProperties];
        
        if (unuploadedProperties.count > 0 || forceUpdate) {
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
            userInfo[@"alias"] = [FDUtilities currentUserAlias];
            userInfo[@"meta"] = metaInfo;
            NSDictionary *deviceProps = [FDUtilities deviceInfoProperties];
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
    if(![HLUser isUserRegistered]) {
        return nil; // This should never happen .. just a safety check
    }
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FDUtilities currentUserAlias];
    if (!userAlias) return nil;
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_USER_PROPERTIES_PATH,appID,userAlias];
    NSData *encodedInfo = [NSJSONSerialization dataWithJSONObject:info  options:NSJSONWritingPrettyPrinted error:nil];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithMethod:HTTP_METHOD_PUT];
    [request setBody:encodedInfo];
    [request setRelativePath:path andURLParams:@[appKey]];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
        if (!error) {
            NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
            if(statusCode == 200){
                FDLog(@"Pushed properties to server %@", info);
                NSDictionary *response = responseInfo.responseAsDictionary;
                [FDUtilities updateUserWithExternalID:[response objectForKey:@"identifier"] withRestoreID:[response objectForKey:@"restoreId"]];
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
    if([FDUtilities canMakeDAUCall]){
        [[FDSecureStore sharedInstance] setObject:[NSDate date] forKey:HOTLINE_DEFAULTS_DAU_LAST_UPDATED_TIME];
        FDSecureStore *store = [FDSecureStore sharedInstance];
        NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
        NSString *userAlias = [[FDUtilities currentUserAlias] length] ? [FDUtilities currentUserAlias] : [FDUtilities getUserAliasWithCreate];
        NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
        NSString *path = [NSString stringWithFormat:HOTLINE_API_DAU_PATH,appID,userAlias];
        HLServiceRequest *request = [[HLServiceRequest alloc]initWithMethod:HTTP_METHOD_PUT];
        [request setRelativePath:path andURLParams:@[appKey,@"source=MOBILE"]];
        HLAPIClient *apiClient = [HLAPIClient sharedInstance];
        @try {
            NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
                if (!error) {
                    NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
                    if(statusCode == 200){
                        FDLog(@"**** DAU call made ****");
                    }
                }else{
                    FDLog(@"Could not make DAU call %@", error);
                    FDLog(@"Response : %@", responseInfo.response);
                    [[FDSecureStore sharedInstance] removeObjectWithKey:HOTLINE_DEFAULTS_DAU_LAST_UPDATED_TIME];
                }
            }];
            
            return task;
        }
        @catch (NSException *exception) {
            [[FDSecureStore sharedInstance] removeObjectWithKey:HOTLINE_DEFAULTS_DAU_LAST_UPDATED_TIME];
            FDLog(@"Activity request failed due to an error %@", exception.description);
        }
    }
    return nil;
}

+(NSURLSessionDataTask *)performSessionCall{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FDUtilities currentUserAlias];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_SESSION_PATH,appID,userAlias];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithMethod:HTTP_METHOD_POST];
    [request setRelativePath:path andURLParams:@[appKey]];
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
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
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FDUtilities currentUserAlias];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_HEARTBEAT_PATH,appID,userAlias];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithMethod:HTTP_METHOD_POST];
    [request setRelativePath:path andURLParams:@[appKey]];
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
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

+(NSURLSessionDataTask *)registerUserConversationActivity :(Message *)message{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FDUtilities currentUserAlias];
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
    if (!([FCRemoteConfig sharedInstance].accountActive && [HLUser isUserRegistered])){
        return;
    }
    NSManagedObjectContext *context = [[KonotorDataManager sharedInstance]mainObjectContext];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_MESSAGE_ENTITY];
    
    NSPredicate *queryChannelAndRead = [NSPredicate predicateWithFormat:@"isRead == 1 AND belongsToChannel == %@", channel];
    NSPredicate *queryType = [NSPredicate predicateWithFormat:@"isWelcomeMessage == 0 AND messageUserAlias != %@", USER_TYPE_MOBILE];
    request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[queryChannelAndRead, queryType]];
    NSArray *messages = [context executeFetchRequest:request error:nil];
    
    NSSortDescriptor *sortDesc =[[NSSortDescriptor alloc] initWithKey:@"createdMillis" ascending:NO];
    Message *latestMessage = [messages sortedArrayUsingDescriptors:@[sortDesc]].firstObject;
    if(latestMessage){
        //update read activity
        if( [FCRemoteConfig sharedInstance].enabledFeatures.inboxEnabled && [FCRemoteConfig sharedInstance].accountActive ){
            [HLCoreServices registerUserConversationActivity:latestMessage];
        }
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

+(NSURLSessionDataTask *)fetchRemoteConfig{
    
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    NSString *path = [NSString stringWithFormat:FRESHCHAT_API_REMOTE_CONFIG_PATH,appID];
    
    NSURL *configBaseUrl = [NSURL URLWithString:[NSString stringWithFormat:HOTLINE_USER_DOMAIN,[NSString stringWithFormat:FRESHCHAT_API_REMOTE_CONFIG_PREFIX,[store objectForKey:HOTLINE_DEFAULTS_DOMAIN]]]];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:configBaseUrl andMethod:HTTP_METHOD_GET];
    
    [request setRelativePath:path andURLParams:@[appKey]];
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
        NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
        if(!error && statusCode == 200) {
            NSDictionary *configDict = responseInfo.responseAsDictionary;
            [HLUserDefaults setObject:[NSDate date] forKey:CONFIG_RC_LAST_API_FETCH_INTERVAL_TIME];
            [[FCRemoteConfig sharedInstance] updateRemoteConfig:configDict];
        }
        else {
            FDLog(@"User remote config fetch call failed %@", error);
        }
    }];
    return task;
}

+(NSURLSessionDataTask *)fetchTypicalReply:(void (^)(FDResponseInfo *responseInfo, NSError *error))handler {
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_TYPLICAL_REPLY,appID];
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithMethod:HTTP_METHOD_GET];
    [request setRelativePath:path andURLParams:@[appKey]];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
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

+(NSURLSessionDataTask *)restoreUserWithExtId:(NSString *)extId restoreId:(NSString *)restoreIdVal withCompletion:(void (^)(NSError *))completion{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSMutableArray *params = [[NSMutableArray alloc] init];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    [params addObject:[NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]]];
    if(extId.length >0){
        [params addObject:[NSString stringWithFormat:@"externalId=%@", [FDStringUtil base64EncodedStringFromString:extId]]];
    } else {
        return nil;
    }
    if(restoreIdVal.length > 0){
        [params addObject:[NSString stringWithFormat:@"restoreId=%@",restoreIdVal]];
    } else {
        return nil;
    }
    NSString *path = [NSString stringWithFormat:FRESHCHAT_USER_RESTORE_PATH,appID];
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithMethod:HTTP_METHOD_GET];
    [request setRelativePath:path andURLParams:params];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
        NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
        NSDictionary *response = responseInfo.responseAsDictionary;
        apiClient.FC_IS_USER_OR_ACCOUNT_DELETED = NO;
        if (statusCode == 200) { //If the user is found
            if(response[@"restoreId"] && response[@"identifier"]) {
                if (![[FDUtilities currentUserAlias] isEqual:response[@"alias"]]) {
                    [FDUtilities updateUserWithData:response];
                    [HLUser setUserMessageInitiated];
                    [[FDSecureStore sharedInstance] setBoolValue:YES forKey:HOTLINE_DEFAULTS_IS_USER_REGISTERED];
                    [FDUtilities updateUserWithExternalID:response[@"identifier"] withRestoreID:response[@"restoreId"]];
                    [[Freshchat sharedInstance] performPendingTasks];
                }
            }
        } else { //If the user is not found
            FreshchatUser* oldUser = [FreshchatUser sharedInstance];
            oldUser.externalID = extId;
            oldUser.restoreID = nil;
            [[Freshchat sharedInstance] setUser:oldUser];
            [FDUtilities resetAlias];
            [FDLocalNotification post:FRESHCHAT_USER_RESTORE_ID_GENERATED info:@{}];
            [[Freshchat sharedInstance] performPendingTasks];
        }
        
        if(completion){
            completion(error);
        }
    }];
    return task;
}

+(void) resetUserData:(void (^)())completion {    
    [FreshchatUser sharedInstance].isRestoring = true;
    [FDLocalNotification post:FRESHCHAT_USER_RESTORE_STATE info:@{@"state":@0}];
    [[KonotorDataManager sharedInstance] clearUserExceptTags:^(NSError *error) {
        FDSecureStore *store = [FDSecureStore sharedInstance];
        // Store the user again to send uninstall api again
        NSDictionary *previousUser = [[Freshchat sharedInstance] getPreviousUserConfig];
        BOOL isUserRegistered = [HLUser isUserRegistered];
        if(previousUser && isUserRegistered) {
            [[Freshchat sharedInstance] storePreviousUser:previousUser inStore:store];
        } else {
            [[Freshchat sharedInstance] storePreviousUser:nil inStore:store];
        }
        // Clear the Channel & Coversation call to fetch again.
        [store removeObjectWithKey:HOTLINE_DEFAULTS_VOTED_ARTICLES];        
        [store removeObjectWithKey:HOTLINE_DEFAULTS_CHANNELS_LAST_UPDATED_SERVER_TIME];
        [store removeObjectWithKey:HOTLINE_DEFAULTS_CONVERSATIONS_LAST_UPDATED_SERVER_TIME];
        [store removeObjectWithKey:HOTLINE_DEFAULTS_CHANNELS_LAST_UPDATED_INTERVAL_TIME];
        [store removeObjectWithKey:HOTLINE_DEFAULTS_CONVERSATIONS_LAST_UPDATED_INTERVAL_TIME];
        
        // Clear the token again to register again
        [store removeObjectWithKey:HOTLINE_DEFAULTS_IS_DEVICE_TOKEN_REGISTERED];
        [store removeObjectWithKey:HOTLINE_DEFAULTS_DAU_LAST_UPDATED_TIME];
        [HLUserDefaults removeObjectForKey:FRESHCHAT_DEFAULTS_SESSION_UPDATED_TIME];
        [[FDVotingManager sharedInstance].votedArticlesDictionary removeAllObjects];
        [KonotorUser removeUserInfo];
        if(completion){
            completion(error);
        }
    }];
}

@end
