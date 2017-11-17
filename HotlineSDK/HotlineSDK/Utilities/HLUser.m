//
//  HLUser.m
//  HotlineSDK
//
//  Created by user on 28/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "HLUserDefaults.h"
#import "FDUtilities.h"
#import "HLCoreServices.h"
#import "HLUser.h"
#import "FDSecureStore.h"

@implementation HLUser

static bool IS_USER_REGISTRATION_IN_PROGRESS = NO;

+(void)registerUser:(void(^)(NSError *error))completion{
    @synchronized ([HLUser class]) {
        if ([HLUser canRegisterUser]) {
            if (IS_USER_REGISTRATION_IN_PROGRESS == NO) {
                
                IS_USER_REGISTRATION_IN_PROGRESS = YES;
                
                BOOL isUserRegistered = [HLUser isUserRegistered];
                if (!isUserRegistered) {
                    [[[HLCoreServices alloc]init] registerUser:^(NSError *error) {
                        if (!error) {
                            [FDUtilities initiatePendingTasks];
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
        }
    }
}

+(BOOL) createUserAOT{
    return [[FDSecureStore sharedInstance] boolValueForKey:HOTLINE_DEFAULTS_IS_USER_REGISTERED];
}

+(BOOL)hasMessageIintiated {
    return [HLUserDefaults getBoolForKey:HOTLINE_DEFAULTS_IS_MESSAGE_SENT];
}

+(void)setUserMessageInitiated {
    [HLUserDefaults setBool:true forKey:HOTLINE_DEFAULTS_IS_MESSAGE_SENT];
}

+(BOOL)canRegisterUser {
    return ( [HLUser createUserAOT] || [HLUser hasMessageIintiated] ) && ![HLUser isUserRegistered];
}

+(BOOL)isUserRegistered {
    NSString *userAlias = [FDUtilities currentUserAlias];
    return ([[FDSecureStore sharedInstance] boolValueForKey:HOTLINE_DEFAULTS_IS_USER_REGISTERED] &&
            (userAlias && userAlias.length > 0));
}



@end
