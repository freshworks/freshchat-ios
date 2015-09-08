//
//  MobihelpAppState.h
//  FreshdeskSDK
//
//  Created by AravinthChandran on 24/11/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MobihelpAppState : NSObject

@property (nonatomic) BOOL isAppDeleted;
@property (nonatomic) BOOL isAppInvalid;
@property (nonatomic) BOOL isAccountSuspended;

+(instancetype)sharedMobihelpAppState;
-(NSError *)getAppErrorForCurrentState;
-(BOOL)isAppDisabled;
-(void)logAppState;

@end
