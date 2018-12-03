//
//  KonotorUser.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 15/02/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FCUsers.h"
#import "FCUserProperties.h"
#import "FCDataManager.h"
#import "FCMacros.h"
#import "FCUtilities.h"
#import "FCSecureStore.h"
#import "FCJWTUtilities.h"

@implementation FCUsers

@dynamic appSpecificIdentifier;
@dynamic email;
@dynamic isUserCreatedOnServer;
@dynamic name;
@dynamic phoneNumber;
@dynamic countryCode;
@dynamic userAlias;
@dynamic hasProperties;

+(void)storeUserInfo:(FreshchatUser *)userInfo{
    
    [[FCDataManager sharedInstance].mainObjectContext performBlock:^{
        FCSecureStore *store = [FCSecureStore sharedInstance];
        
        if (userInfo.firstName && ![userInfo.firstName isEqualToString:@""]) {
            [store setObject:userInfo.firstName forKey:HOTLINE_DEFAULTS_USER_FIRST_NAME];
            [FCUserProperties createNewPropertyForKey:@"firstName" WithValue:userInfo.firstName isUserProperty:YES];
        }
        
        if (userInfo.lastName && ![userInfo.lastName isEqualToString:@""]) {
            [store setObject:userInfo.lastName forKey:HOTLINE_DEFAULTS_USER_LAST_NAME];
            [FCUserProperties createNewPropertyForKey:@"lastName" WithValue:userInfo.lastName isUserProperty:YES];
        }
        
        if (userInfo.email && [FCStringUtil isValidEmail:userInfo.email]) {
            [store setObject:userInfo.email forKey:HOTLINE_DEFAULTS_USER_EMAIL];
            [FCUserProperties createNewPropertyForKey:@"email" WithValue:userInfo.email isUserProperty:YES];
        }
        
        if (userInfo.phoneNumber && ![userInfo.phoneNumber isEqualToString:@""]) {
            [store setObject:userInfo.phoneNumber forKey:HOTLINE_DEFAULTS_USER_PHONE_NUMBER];
            [FCUserProperties createNewPropertyForKey:@"phone" WithValue:userInfo.phoneNumber isUserProperty:YES];
        }
        
        if (userInfo.phoneCountryCode && ![userInfo.phoneCountryCode isEqualToString:@""]) {
            [store setObject:userInfo.phoneCountryCode forKey:HOTLINE_DEFAULTS_USER_PHONE_COUNTRY_CODE];
            [FCUserProperties createNewPropertyForKey:@"phoneCountry" WithValue:userInfo.phoneCountryCode isUserProperty:YES];
        }
        
        [store setObject:userInfo.restoreID forKey:HOTLINE_DEFAULTS_USER_RESTORE_ID];
        [FCUserProperties createNewPropertyForKey:@"restoreId" WithValue:userInfo.restoreID isUserProperty:YES];
        [store setObject:userInfo.externalID forKey:HOTLINE_DEFAULTS_USER_EXTERNAL_ID];
        [FCUserProperties createNewPropertyForKey:@"identifier" WithValue:userInfo.externalID isUserProperty:YES];
        [store setObject:userInfo.jwtToken forKey:HOTLINE_DEFAULTS_USER_JWT_TOKEN];
        [FCUserProperties createNewPropertyForKey:@"jwtToken" WithValue:userInfo.jwtToken isUserProperty:YES];
        [[FCDataManager sharedInstance]save];
    }];
}

+ (void) updateUserWithIdToken : (NSString *) jwtIdToken {
    FreshchatUser *fcUser = [FreshchatUser sharedInstance];
    fcUser.jwtToken = jwtIdToken;
    [FCUsers storeUserInfo:fcUser];
}

+(void) removeUserInfo {
    FCSecureStore *store = [FCSecureStore sharedInstance];
    [store removeObjectWithKey:HOTLINE_DEFAULTS_USER_FIRST_NAME];
    [store removeObjectWithKey:HOTLINE_DEFAULTS_USER_LAST_NAME];
    [store removeObjectWithKey:HOTLINE_DEFAULTS_USER_EMAIL];
    [store removeObjectWithKey:HOTLINE_DEFAULTS_USER_PHONE_NUMBER];
    [store removeObjectWithKey:HOTLINE_DEFAULTS_USER_PHONE_COUNTRY_CODE];
    [store removeObjectWithKey:HOTLINE_DEFAULTS_USER_RESTORE_ID];
    [store removeObjectWithKey:HOTLINE_DEFAULTS_USER_EXTERNAL_ID];
    [store removeObjectWithKey:HOTLINE_DEFAULTS_USER_JWT_TOKEN];
    [FreshchatUser sharedInstance].firstName = nil;
    [FreshchatUser sharedInstance].lastName = nil;
    [FreshchatUser sharedInstance].email = nil;
    [FreshchatUser sharedInstance].phoneNumber = nil;
    [FreshchatUser sharedInstance].phoneCountryCode = nil;
    [FreshchatUser sharedInstance].restoreID = nil;
    [FreshchatUser sharedInstance].externalID = nil;
    [FreshchatUser sharedInstance].jwtToken = nil;
}

+(FCUsers *)getUser{
    FCUsers *user = nil;
    NSManagedObjectContext *context = [[FCDataManager sharedInstance]mainObjectContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_USERS_ENTITY];
    NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
    if (matches.count == 1) {
        user = matches.firstObject;
    }
    if (matches.count > 1) {
        user = nil;
        FDLog(@"Attention! Duplicates found in users table !");
    }
    return user;
}

@end
