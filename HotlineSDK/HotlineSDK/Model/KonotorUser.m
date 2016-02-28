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

+(void)storeUserInfo:(HotlineUser *)userInfo{
    
    FDSecureStore *store = [FDSecureStore sharedInstance];
    
    if (userInfo.name && ![userInfo.name isEqualToString:@""]) {
        [store setObject:userInfo.name forKey:HOTLINE_DEFAULTS_USER_NAME];
        [KonotorCustomProperty createNewPropertyForKey:@"name" WithValue:userInfo.name isUserProperty:YES];
    }
    
    if (userInfo.email && [FDUtilities isValidEmail:userInfo.email]) {
        [store setObject:userInfo.email forKey:HOTLINE_DEFAULTS_USER_EMAIL];
        [KonotorCustomProperty createNewPropertyForKey:@"email" WithValue:userInfo.email isUserProperty:YES];
    }
    
    if (userInfo.externalID && ![userInfo.externalID isEqualToString:@""]) {
        [store setObject:userInfo.externalID forKey:HOTLINE_DEFAULTS_USER_EXTERNAL_ID];
        [KonotorCustomProperty createNewPropertyForKey:@"identifier" WithValue:userInfo.externalID isUserProperty:YES];
    }
    
    if (userInfo.phoneNumber && ![userInfo.phoneNumber isEqualToString:@""]) {
        [store setObject:userInfo.phoneNumber forKey:HOTLINE_DEFAULTS_USER_PHONE_NUMBER];
        [KonotorCustomProperty createNewPropertyForKey:@"phone" WithValue:userInfo.phoneNumber isUserProperty:YES];
    }
    
    if (userInfo.phoneCountryCode && ![userInfo.phoneCountryCode isEqualToString:@""]) {
        [store setObject:userInfo.phoneCountryCode forKey:HOTLINE_DEFAULTS_USER_PHONE_COUNTRY_CODE];
        [KonotorCustomProperty createNewPropertyForKey:@"phoneCountry" WithValue:userInfo.phoneCountryCode isUserProperty:YES];
    }
    
    [[KonotorDataManager sharedInstance]save];
    
}

+(KonotorUser *)getUser{
    KonotorUser *user = nil;
    NSManagedObjectContext *context = [[KonotorDataManager sharedInstance]mainObjectContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"KonotorUser"];
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