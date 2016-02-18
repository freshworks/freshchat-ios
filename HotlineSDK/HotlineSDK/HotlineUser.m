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

@interface HotlineUser ()

@property (strong, nonatomic, readwrite) NSMutableDictionary *userProperty;
@property BOOL dirty;

@end

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
        self.dirty = [[FDSecureStore sharedInstance] boolValueForKey:HOTLINE_DEFAULTS_DIRTY];
    }
}

-(void) markDirty {
    _dirty = YES;
    [[FDSecureStore sharedInstance] setBoolValue:@YES forKey:HOTLINE_DEFAULTS_DIRTY];
}

-(void) setName:(NSString *) name{
    _name = name;
    [self markDirty];
}

-(void) setEmail:(NSString *) email{
    _email = email;
    [self markDirty];
}

-(void) setPhoneNumber:(NSString *) phone withCountryCode:(NSString *)countryCode{
    _phoneCountryCode = countryCode;
    _phoneNumber = phone;
    [self markDirty];
}

-(void) setExternalId:(NSString *)identifier{
    _externalID = identifier;
    [self markDirty];
}

-(void) setUserPropertyforKey:(NSString *) key withValue:(NSString *)value{
    if (key.length > 0 && value.length > 0){
        [self.userProperty setObject:value forKey:key];
        [KonotorCustomProperty createNewPropertyForKey:key WithValue:value isUserProperty:NO];
        [self markDirty];
    }
}

-(void) update{
    if([self dirty] &&
       [[FDSecureStore sharedInstance] boolValueForKey:HOTLINE_DEFAULTS_IS_USER_REGISTERED]){
       
        [KonotorUser createUserWithInfo:self];
        [HLCoreServices uploadUnuploadedProperties];
        _dirty = NO;
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