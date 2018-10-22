//
//  JWTAuthValidator.m
//  FreshchatSDK
//
//  Created by Sanjith Kanagavel on 05/10/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import "FCJWTAuthValidator.h"
#import "FCSecureStore.h"

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
        self.prevState = TOKEN_NOT_SET;
        self.currState = [self setDefaultJWTState];
    }
    return self;
}

-(enum JWT_STATE) setDefaultJWTState {
    NSNumber *stateNumb = [[FCSecureStore sharedInstance] objectForKey:FRESHCHAT_DEFAULTS_AUTH_STATE];
    if(stateNumb != nil) {
        return (enum JWT_STATE)[stateNumb intValue];
    }
    return TOKEN_NOT_SET;
}

- (void) updateAuthState : (enum JWT_STATE) state{
    [FCJWTAuthValidator sharedInstance].currState = state;
    [[FCSecureStore sharedInstance] setIntValue:(int)state forKey:FRESHCHAT_DEFAULTS_AUTH_STATE];
    [[NSNotificationCenter defaultCenter] postNotificationName:JWT_EVENT object:nil];
}

-(enum JWT_UI_STATE) getUiActionForTokenState: (enum JWT_STATE) apiState {
        switch (apiState) {
            case TOKEN_VALID:
                return SHOW_CONTENT;
            case TOKEN_NOT_SET:
            case TOKEN_NOT_PROCESSED:
            case TOKEN_EXPIRED:
                return LOADING;
            case TOKEN_INVALID:
                return SHOW_ALERT;
            default:
                return NO_CHANGE;
        }
}

-(enum JWT_UI_STATE) getUiActionForTransition {

    if([FCJWTAuthValidator sharedInstance].currState == TOKEN_VALID ||
       [FCJWTAuthValidator sharedInstance].currState == TOKEN_INVALID ||
       [FCJWTAuthValidator sharedInstance].currState == TOKEN_NOT_SET) {
        return [[FCJWTAuthValidator sharedInstance] getUiActionForTokenState: [FCJWTAuthValidator sharedInstance].currState];
    } else if([FCJWTAuthValidator sharedInstance].currState == TOKEN_EXPIRED) {
        if ([FCJWTAuthValidator sharedInstance].prevState == TOKEN_VALID) {
            return SHOW_CONTENT;
        } else {
            return LOADING;
        }
    } else if([FCJWTAuthValidator sharedInstance].currState == TOKEN_NOT_PROCESSED) {
        if([FCJWTAuthValidator sharedInstance].prevState == TOKEN_EXPIRED){
            return SHOW_CONTENT;
        } else {
            return LOADING;
        }
    }
    
    return NO_CHANGE;
}





@end
