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

@implementation HotlineUser

+(instancetype)sharedInstance{
    static HotlineUser *hotlineUser = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hotlineUser = [[self alloc]init];
    });
    return hotlineUser;
}

-(void)clearUserData{
        
    self.userName = nil;
    self.emailAddress = nil;
    self.phoneNumber = nil;
    self.externalID = nil;

    FDSecureStore *store = [FDSecureStore sharedInstance];
    [store setObject:nil forKey:HOTLINE_DEFAULTS_USER_NAME];
    [store setObject:nil forKey:HOTLINE_DEFAULTS_USER_EMAIL];
    [store setObject:nil forKey:HOTLINE_DEFAULTS_USER_PHONE_NUMBER];
    [store setObject:nil forKey:HOTLINE_DEFAULTS_USER_EXTERNAL_ID];
}

@end