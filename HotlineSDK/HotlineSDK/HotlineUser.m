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
        [hotlineUser copyFrom:[KonotorUser getUser]];
    });
    return hotlineUser;
}

-(void)copyFrom:(KonotorUser *)konotorUser{
    if(konotorUser){
        if(konotorUser.email){
            self.email =konotorUser.email;
        }
        if(konotorUser.name){
            self.name =konotorUser.name;
        }
        if(konotorUser.countryCode){
            self.phoneCountryCode =konotorUser.countryCode;
        }
        if(konotorUser.phoneNumber){
            self.phoneNumber =konotorUser.phoneNumber;
        }
        if(konotorUser.appSpecificIdentifier){
            self.externalID =konotorUser.appSpecificIdentifier;
        }
    }
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