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
    self.countryCode = nil;

    [[FDSecureStore sharedInstance]clearStoreData];
}

@end