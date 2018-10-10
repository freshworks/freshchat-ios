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
    self.prevState = NONE;
    self.currState = ACTIVE;
}

-(void)fireChange {
    [JWTAuthValidator sharedInstance].prevState = [JWTAuthValidator sharedInstance].currState;
    switch ([JWTAuthValidator sharedInstance].currState) {
        case ACTIVE:
            self.currState = WAIT_FOR_FIRST_TOKEN;
            break;
        case WAIT_FOR_FIRST_TOKEN:
            self.currState = VERIFICATION_UNDER_PROGRESS;
            break;
        case VERIFICATION_UNDER_PROGRESS:
            self.currState = WAITING_FOR_REFRESH_TOKEN;
            break;
        case WAITING_FOR_REFRESH_TOKEN:
            self.currState = TOKEN_VERIFICATION_FAILED;
            break;
        case TOKEN_VERIFICATION_FAILED:
            self.currState = ACTIVE;
            break;
        default:
            break;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:JWT_EVENT object:nil];
}

-(enum JWT_UI_STATE) getUiActionForTokenState: (enum JWT_STATE) apiState {
    if(apiState != NONE) {
        switch (apiState) {
            case ACTIVE:
                return SHOW_CONTENT;
            case WAIT_FOR_FIRST_TOKEN:
            case VERIFICATION_UNDER_PROGRESS:
            case WAITING_FOR_REFRESH_TOKEN:
                return LOADING;
            case TOKEN_VERIFICATION_FAILED:
                return SHOW_ALERT;
            default:
                return NO_CHANGE;
        }
    }
    return NO_CHANGE;
}

-(enum JWT_UI_STATE) getUiActionForTransition {
    if([JWTAuthValidator sharedInstance].currState == [JWTAuthValidator sharedInstance].prevState) {
        return NO_CHANGE;
    }
    
    if([JWTAuthValidator sharedInstance].prevState == NONE) {
        return [[JWTAuthValidator sharedInstance] getUiActionForTokenState:[JWTAuthValidator sharedInstance].currState];
    }

    if([JWTAuthValidator sharedInstance].currState == NONE) {
        return [[JWTAuthValidator sharedInstance] getUiActionForTokenState: [JWTAuthValidator sharedInstance].prevState];
    }

    if([JWTAuthValidator sharedInstance].currState == ACTIVE) {
        return [[JWTAuthValidator sharedInstance] getUiActionForTokenState: [JWTAuthValidator sharedInstance].currState];
    } else if([JWTAuthValidator sharedInstance].currState == TOKEN_VERIFICATION_FAILED) {
        return [[JWTAuthValidator sharedInstance] getUiActionForTokenState: [JWTAuthValidator sharedInstance].currState];
    } else if([JWTAuthValidator sharedInstance].currState == WAIT_FOR_FIRST_TOKEN) {
        return [[JWTAuthValidator sharedInstance] getUiActionForTokenState: [JWTAuthValidator sharedInstance].currState];
    } else if([JWTAuthValidator sharedInstance].currState == WAITING_FOR_REFRESH_TOKEN) {
        if ([JWTAuthValidator sharedInstance].prevState == ACTIVE) {
            return SHOW_CONTENT;
        }
        return LOADING;
    } else if([JWTAuthValidator sharedInstance].currState == VERIFICATION_UNDER_PROGRESS) {
        if([JWTAuthValidator sharedInstance].prevState == ACTIVE || [JWTAuthValidator sharedInstance].prevState == WAITING_FOR_REFRESH_TOKEN){
            return SHOW_CONTENT;
        } else {
            return LOADING;
        }
    }
    
    return NO_CHANGE;
}





@end
