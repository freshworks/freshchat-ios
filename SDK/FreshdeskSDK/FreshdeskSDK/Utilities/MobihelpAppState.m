//
//  MobihelpAppState.m
//  FreshdeskSDK
//
//  Created by AravinthChandran on 24/11/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "MobihelpAppState.h"
#import "FDSecureStore.h"
#import "FDError.h"

@interface MobihelpAppState ()

@property (strong, nonatomic) FDSecureStore *secureStore;

@end

@implementation MobihelpAppState

#pragma mark - Initializer

+ (instancetype)sharedMobihelpAppState {
    static MobihelpAppState *_sharedMobihelpAppState = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedMobihelpAppState = [[self alloc]init];
    });
    return _sharedMobihelpAppState;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.isAppDeleted       = [self.secureStore boolValueForKey:MOBIHELP_DEFAULTS_IS_APP_DELETED];
        self.isAppInvalid       = [self.secureStore boolValueForKey:MOBIHELP_DEFAULTS_IS_INVALID_APP];
        self.isAccountSuspended = [self.secureStore boolValueForKey:MOBIHELP_DEFAULTS_IS_ACCOUNT_SUSPENDED];
    }
    return self;
}

#pragma mark - Lazy Instantiations

-(FDSecureStore *)secureStore{
    if(!_secureStore){
        _secureStore = [FDSecureStore sharedInstance];
    }
    return _secureStore;
}

-(BOOL)isAppDisabled{
    return (!self.isAppDeleted && !self.isAccountSuspended) ? YES : NO ;
}

-(void)setIsAppDeleted:(BOOL)isAppDeleted{
    [self.secureStore setBoolValue:isAppDeleted forKey:MOBIHELP_DEFAULTS_IS_APP_DELETED];
}

-(void)setIsAppInvalid:(BOOL)isAppInvalid{
    [self.secureStore setBoolValue:isAppInvalid forKey:MOBIHELP_DEFAULTS_IS_INVALID_APP];
}

-(void)setIsAccountSuspended:(BOOL)isAccountSuspended{
    [self.secureStore setBoolValue:isAccountSuspended forKey:MOBIHELP_DEFAULTS_IS_ACCOUNT_SUSPENDED];
}

-(BOOL)isAppDeleted{
    return [self.secureStore boolValueForKey:MOBIHELP_DEFAULTS_IS_APP_DELETED];
}

-(BOOL)isAppInvalid{
    return [self.secureStore boolValueForKey:MOBIHELP_DEFAULTS_IS_INVALID_APP];
}

-(BOOL)isAccountSuspended{
    return [self.secureStore boolValueForKey:MOBIHELP_DEFAULTS_IS_ACCOUNT_SUSPENDED];
}

-(NSError *)getAppErrorForCurrentState{
    
    NSMutableArray *errors = [[NSMutableArray alloc]init];
    
    FDError *error;

    if (self.isAppDeleted) {
        [errors addObject:[[FDError alloc]initWithError:MOBIHELP_ERROR_APP_DELETED]];
    }
    
    if (self.isAccountSuspended) {
        [errors addObject:[[FDError alloc]initWithError:MOBIHELP_ERROR_ACCOUNT_SUSPENDED]];
    }
    
    if (self.isAppInvalid) {
        [errors addObject:[[FDError alloc]initWithError:MOBIHELP_ERROR_INVALID_APP_CREDENTIALS]];
    }
    
    if ([errors count]>1) {
        error = [[FDError alloc]initWithMultipleErrors:errors];
    }else{
        error = [errors lastObject];
    }
    
    return error;
}

-(void)logAppState{
    if (self.isAppDeleted) {
        NSLog(@"Warning: This app is deleted from the portal");
    }
    if (self.isAccountSuspended) {
        NSLog(@"Warning: This account is suspended");
    }
    if (self.isAppInvalid) {
        NSLog(@"Warning: App key or app secret is invalid for this app");
    }
}

@end
