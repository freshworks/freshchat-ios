 //
//  HLUser.m
//  HotlineSDK
//
//  Created by user on 28/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCUserDefaults.h"
#import "FCUtilities.h"
#import "FCCoreServices.h"
#import "FCUserUtil.h"
#import "FCSecureStore.h"
#import "FCJWTUtilities.h"
#import "FCRemoteConfig.h"

@implementation FCUserUtil

static bool IS_USER_REGISTRATION_IN_PROGRESS = NO;

+(void)registerUser:(void(^)(NSError *error))completion{
    if([[FCRemoteConfig sharedInstance] isUserAuthEnabled] && ![FreshchatUser sharedInstance].jwtToken){
        return;
    }
    @synchronized ([FCUserUtil class]) {
        if ([FCUserUtil canRegisterUser]) {
            if (IS_USER_REGISTRATION_IN_PROGRESS == NO) {
                
                IS_USER_REGISTRATION_IN_PROGRESS = YES;
                
                BOOL isUserRegistered = [FCUserUtil isUserRegistered];
                if (!isUserRegistered) {
                    [[[FCCoreServices alloc]init] registerUser:^(NSError *error) {
                        if (!error) {
                            [FCUtilities initiatePendingTasks];
                        }
                        dispatch_async(dispatch_get_main_queue(), ^ {
                            IS_USER_REGISTRATION_IN_PROGRESS = NO;
                            if (completion) {
                                completion(error);
                            }
                        });
                        
                    }];
                }else{
                    IS_USER_REGISTRATION_IN_PROGRESS = NO;
                    if (completion) {
                        completion(nil);
                    }
                }
            }
        } else {
            if (completion) {
                completion(nil);
            }
        }
    }
}

+(BOOL) createUserAOT{
    if([[FCSecureStore sharedInstance] boolValueForKey:FRESHCHAT_CONFIG_RC_AOT_USER_CREATE_ENABLED]){
        return [[FCSecureStore sharedInstance] boolValueForKey:FRESHCHAT_CONFIG_RC_AOT_USER_CREATE_ENABLED];
    }
    return false;
}

+(BOOL)hasMessageIintiated {
    return [FCUserDefaults getBoolForKey:HOTLINE_DEFAULTS_IS_MESSAGE_SENT];
}

+(void)setUserMessageInitiated {
    [FCUserDefaults setBool:true forKey:HOTLINE_DEFAULTS_IS_MESSAGE_SENT];
}

+(BOOL)canRegisterUser {
    return ([FCUserUtil createUserAOT] || [FCUserUtil hasMessageIintiated]) && ![FCUserUtil isUserRegistered];
    
}

+(BOOL)isUserRegistered {
    NSString *userAlias = [FCUtilities currentUserAlias];
    return ([[FCSecureStore sharedInstance] boolValueForKey:HOTLINE_DEFAULTS_IS_USER_REGISTERED] &&
            (userAlias && userAlias.length > 0));
}



@end
