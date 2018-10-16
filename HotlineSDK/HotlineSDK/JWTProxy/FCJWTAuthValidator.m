//
//  JWTAuthValidator.m
//  FreshchatSDK
//
//  Created by Sanjith Kanagavel on 05/10/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import "FCJWTAuthValidator.h"

@implementation FCJWTAuthValidator

+ (instancetype)sharedInstance {
    static FCJWTAuthValidator *sharedJWTAuthValidator = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedJWTAuthValidator = [[self alloc]init];
    });
    return sharedJWTAuthValidator;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.prevState = NONE;
        self.currState = NONE;
    }
    return self;
}

- (void) updateAuthState : (enum JWT_STATE) state{
    [FCJWTAuthValidator sharedInstance].currState = state;
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
    if([FCJWTAuthValidator sharedInstance].currState == [FCJWTAuthValidator sharedInstance].prevState) {
        return NO_CHANGE;
    }
    
    if([FCJWTAuthValidator sharedInstance].prevState == NONE) {
        return [[FCJWTAuthValidator sharedInstance] getUiActionForTokenState:[FCJWTAuthValidator sharedInstance].currState];
    }

    if([FCJWTAuthValidator sharedInstance].currState == NONE) {
        return [[FCJWTAuthValidator sharedInstance] getUiActionForTokenState: [FCJWTAuthValidator sharedInstance].prevState];
    }

    if([FCJWTAuthValidator sharedInstance].currState == ACTIVE) {
        return [[FCJWTAuthValidator sharedInstance] getUiActionForTokenState: [FCJWTAuthValidator sharedInstance].currState];
    } else if([FCJWTAuthValidator sharedInstance].currState == TOKEN_VERIFICATION_FAILED) {
        return [[FCJWTAuthValidator sharedInstance] getUiActionForTokenState: [FCJWTAuthValidator sharedInstance].currState];
    } else if([FCJWTAuthValidator sharedInstance].currState == WAIT_FOR_FIRST_TOKEN) {
        return [[FCJWTAuthValidator sharedInstance] getUiActionForTokenState: [FCJWTAuthValidator sharedInstance].currState];
    } else if([FCJWTAuthValidator sharedInstance].currState == WAITING_FOR_REFRESH_TOKEN) {
        if ([FCJWTAuthValidator sharedInstance].prevState == ACTIVE) {
            return SHOW_CONTENT;
        }
        return LOADING;
    } else if([FCJWTAuthValidator sharedInstance].currState == VERIFICATION_UNDER_PROGRESS) {
        if([FCJWTAuthValidator sharedInstance].prevState == ACTIVE || [FCJWTAuthValidator sharedInstance].prevState == WAITING_FOR_REFRESH_TOKEN){
            return SHOW_CONTENT;
        } else {
            return LOADING;
        }
    }
    
    return NO_CHANGE;
}





@end
