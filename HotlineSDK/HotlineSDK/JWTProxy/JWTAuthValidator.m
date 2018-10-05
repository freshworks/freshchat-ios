//
//  JWTAuthValidator.m
//  FreshchatSDK
//
//  Created by Sanjith Kanagavel on 05/10/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import "JWTAuthValidator.h"

@implementation JWTAuthValidator

+ (instancetype)sharedInstance {
    static JWTAuthValidator *sharedJWTAuthValidator = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedJWTAuthValidator = [[self alloc]init];
    });
    return sharedJWTAuthValidator;
}

+ (void) postNotification:(enum API_STATES)state {
    NSString *value = @"";
    switch (state) {
        case ACTIVE:
            value = ACTIVE_EVENT;
            break;
        case WAIT_FOR_FIRST_TOKEN:
            value = WAIT_FOR_FIRST_TOKEN_EVENT;
            break;
        case VERIFICATION_UNDER_PROGRESS:
            value = VERIFICATION_UNDER_PROGRESS_EVENT;
            break;
        case WAITING_FOR_REFRESH_TOKEN:
            value = WAITING_FOR_REFRESH_TOKEN_EVENT;
            break;
        case TOKEN_VERIFICATION_FAILED:
            value = TOKEN_VERIFICATION_FAILED_EVENT;
            break;
        default:
            break;
    }
    if (![value isEqualToString:@""]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:value object:nil];        
    }
}

- (instancetype)init{
    self = [super init];
    if (self) {
        [self startTimer];
    }
    return self;
}

-(void) startTimer {
    _timer = [NSTimer scheduledTimerWithTimeInterval:10.0
                                             target:self
                                           selector:@selector(fireChange)
                                           userInfo:nil
                                            repeats:true];
    _state = ACTIVE;
}

-(void)fireChange {
    switch (_state) {
        case ACTIVE:
            _state = WAIT_FOR_FIRST_TOKEN;
            break;
        case WAIT_FOR_FIRST_TOKEN:
            _state = VERIFICATION_UNDER_PROGRESS;
            break;
        case VERIFICATION_UNDER_PROGRESS:
            _state = WAITING_FOR_REFRESH_TOKEN;
            break;
        case WAITING_FOR_REFRESH_TOKEN:
            _state = TOKEN_VERIFICATION_FAILED;
            break;
        case TOKEN_VERIFICATION_FAILED:
            _state = ACTIVE;
            break;
        default:
            break;
    }
    [JWTAuthValidator postNotification:_state];
}

-(void) stopTimer {
    
}
@end
