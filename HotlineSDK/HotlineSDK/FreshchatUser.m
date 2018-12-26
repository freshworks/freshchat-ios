//
//  FreshchatUser.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 15/12/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FreshchatSDK.h"
#import "FCSecureStore.h"
#import "FCUtilities.h"
#import "FCUsers.h"
#import "FCCoreServices.h"
#import "FCUserProperties.h"
#import "FCJWTUtilities.h"


@implementation FreshchatUser

+(instancetype)sharedInstance{
    static FreshchatUser *freshchatUser = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        freshchatUser = [[self alloc]init];
        [freshchatUser copyValuesFromStore];
    });
    return freshchatUser;
}

-(void)copyValuesFromStore {
    FCSecureStore *store = [FCSecureStore sharedInstance];
    self.jwtToken = [store objectForKey:HOTLINE_DEFAULTS_USER_JWT_TOKEN];
    self.firstName = [store objectForKey:HOTLINE_DEFAULTS_USER_FIRST_NAME];
    self.lastName = [store objectForKey:HOTLINE_DEFAULTS_USER_LAST_NAME];
    self.email = [store objectForKey:HOTLINE_DEFAULTS_USER_EMAIL];
    self.phoneNumber = [store objectForKey:HOTLINE_DEFAULTS_USER_PHONE_NUMBER];
    self.phoneCountryCode = [store objectForKey:HOTLINE_DEFAULTS_USER_PHONE_COUNTRY_CODE];
    self.externalID = [store objectForKey:HOTLINE_DEFAULTS_USER_EXTERNAL_ID];
    self.restoreID = [store objectForKey:HOTLINE_DEFAULTS_USER_RESTORE_ID];
    
}

-(void)resetUser{
    self.firstName = nil;
    self.lastName = nil;
    self.email = nil;
    self.phoneNumber = nil;
    self.externalID = nil;
    self.phoneCountryCode = nil;
    self.externalID = nil;
    self.restoreID = nil;
    self.jwtToken = nil;
}

@end
