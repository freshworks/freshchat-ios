//
//  KonotorUser.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 15/02/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "KonotorUser.h"
#import "KonotorCustomProperty.h"
#import "KonotorDataManager.h"
#import "HLMacros.h"
#import "FDUtilities.h"
#import "FDSecureStore.h"

@implementation KonotorUser

@dynamic appSpecificIdentifier;
@dynamic email;
@dynamic isUserCreatedOnServer;
@dynamic name;
@dynamic phoneNumber;
@dynamic countryCode;
@dynamic userAlias;
@dynamic hasProperties;

+(void)storeUserInfo:(FreshchatUser *)userInfo{
    
    [[KonotorDataManager sharedInstance].mainObjectContext performBlock:^{
        FDSecureStore *store = [FDSecureStore sharedInstance];
        
        if (userInfo.firstName && ![userInfo.firstName isEqualToString:@""]) {
            [store setObject:userInfo.firstName forKey:HOTLINE_DEFAULTS_USER_FIRST_NAME];
            [KonotorCustomProperty createNewPropertyForKey:@"firstName" WithValue:userInfo.firstName isUserProperty:YES];
        }
        
        if (userInfo.lastName && ![userInfo.lastName isEqualToString:@""]) {
            [store setObject:userInfo.lastName forKey:HOTLINE_DEFAULTS_USER_LAST_NAME];
            [KonotorCustomProperty createNewPropertyForKey:@"lastName" WithValue:userInfo.lastName isUserProperty:YES];
        }
        
        if (userInfo.email && [FDStringUtil isValidEmail:userInfo.email]) {
            [store setObject:userInfo.email forKey:HOTLINE_DEFAULTS_USER_EMAIL];
            [KonotorCustomProperty createNewPropertyForKey:@"email" WithValue:userInfo.email isUserProperty:YES];
        }
        
        if (userInfo.phoneNumber && ![userInfo.phoneNumber isEqualToString:@""]) {
            [store setObject:userInfo.phoneNumber forKey:HOTLINE_DEFAULTS_USER_PHONE_NUMBER];
            [KonotorCustomProperty createNewPropertyForKey:@"phone" WithValue:userInfo.phoneNumber isUserProperty:YES];
        }
        
        if (userInfo.phoneCountryCode && ![userInfo.phoneCountryCode isEqualToString:@""]) {
            [store setObject:userInfo.phoneCountryCode forKey:HOTLINE_DEFAULTS_USER_PHONE_COUNTRY_CODE];
            [KonotorCustomProperty createNewPropertyForKey:@"phoneCountry" WithValue:userInfo.phoneCountryCode isUserProperty:YES];
        }
        
        [store setObject:userInfo.restoreID forKey:HOTLINE_DEFAULTS_USER_RESTORE_ID];
        [KonotorCustomProperty createNewPropertyForKey:@"restoreId" WithValue:userInfo.restoreID isUserProperty:YES];
        [store setObject:userInfo.externalID forKey:HOTLINE_DEFAULTS_USER_EXTERNAL_ID];
        [KonotorCustomProperty createNewPropertyForKey:@"identifier" WithValue:userInfo.externalID isUserProperty:YES];
        
        [[KonotorDataManager sharedInstance]save];
    }];
}

+(void) removeUserInfo {
    FDSecureStore *store = [FDSecureStore sharedInstance];
    [store removeObjectWithKey:HOTLINE_DEFAULTS_USER_FIRST_NAME];
    [store removeObjectWithKey:HOTLINE_DEFAULTS_USER_LAST_NAME];
    [store removeObjectWithKey:HOTLINE_DEFAULTS_USER_EMAIL];
    [store removeObjectWithKey:HOTLINE_DEFAULTS_USER_PHONE_NUMBER];
    [store removeObjectWithKey:HOTLINE_DEFAULTS_USER_PHONE_COUNTRY_CODE];
    [store removeObjectWithKey:HOTLINE_DEFAULTS_USER_RESTORE_ID];
    [store removeObjectWithKey:HOTLINE_DEFAULTS_USER_EXTERNAL_ID];
    [FreshchatUser sharedInstance].firstName = nil;
    [FreshchatUser sharedInstance].lastName = nil;
    [FreshchatUser sharedInstance].email = nil;
    [FreshchatUser sharedInstance].phoneNumber = nil;
    [FreshchatUser sharedInstance].phoneCountryCode = nil;
    [FreshchatUser sharedInstance].restoreID = nil;
    [FreshchatUser sharedInstance].externalID = nil;
}

+(KonotorUser *)getUser{
    KonotorUser *user = nil;
    NSManagedObjectContext *context = [[KonotorDataManager sharedInstance]mainObjectContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_USER_ENTITY];
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
