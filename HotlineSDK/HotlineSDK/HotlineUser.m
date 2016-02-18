//
//  HotlineUser.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 15/12/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Hotline.h"
#import "FDSecureStore.h"
#import "FDUtilities.h"
#import "KonotorUser.h"
#import "HLCoreServices.h"
#import "KonotorCustomProperty.h"

@implementation HotlineUser

+(instancetype)sharedInstance{
    static HotlineUser *hotlineUser = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hotlineUser = [[self alloc]init];
        [hotlineUser copyValuesFromStore];
    });
    return hotlineUser;
}

-(void)copyValuesFromStore{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    self.name = [store objectForKey:HOTLINE_DEFAULTS_USER_NAME];
    self.email = [store objectForKey:HOTLINE_DEFAULTS_USER_EMAIL];
    self.phoneNumber = [store objectForKey:HOTLINE_DEFAULTS_USER_PHONE_NUMBER];
    self.phoneCountryCode = [store objectForKey:HOTLINE_DEFAULTS_USER_USER_COUNTRY_CODE];
    self.externalID = [store objectForKey:HOTLINE_DEFAULTS_USER_EXTERNAL_ID];
}

-(void)clearUserData{
    self.name = nil;
    self.email = nil;
    self.phoneNumber = nil;
    self.externalID = nil;
    self.phoneCountryCode = nil;
    [[FDSecureStore sharedInstance]clearStoreData];
}

@end