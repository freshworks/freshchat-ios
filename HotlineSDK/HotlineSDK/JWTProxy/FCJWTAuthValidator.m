//
//  JWTAuthValidator.m
//  FreshchatSDK
//
//  Created by Sanjith Kanagavel on 05/10/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import "FCJWTAuthValidator.h"
#import "FCLocalNotification.h"

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
    }
    return self;
}

-(enum JWT_STATE) getDefaultJWTState {
    enum JWT_STATE currentState = TOKEN_NOT_SET;
    NSNumber *stateNumb = [[FCSecureStore sharedInstance] objectForKey:FRESHCHAT_DEFAULTS_AUTH_STATE];
    if(stateNumb != nil) {
        currentState = (enum JWT_STATE)[stateNumb intValue];
    }
    
    if([FCJWTUtilities isValidityExpiedForJWTToken:[FreshchatUser sharedInstance].jwtToken] && currentState != TOKEN_EXPIRED){
        [FCJWTAuthValidator sharedInstance].prevState = currentState;
        currentState = TOKEN_EXPIRED;
        [[FCSecureStore sharedInstance] setIntValue:(int)currentState forKey:FRESHCHAT_DEFAULTS_AUTH_STATE];
        [[NSNotificationCenter defaultCenter] postNotificationName:JWT_EVENT object:nil];
    }
    return currentState;
}

- (void) updateAuthState : (enum JWT_STATE) state{
    [FCJWTAuthValidator sharedInstance].prevState = [[FCJWTAuthValidator sharedInstance] getDefaultJWTState];
    [[FCSecureStore sharedInstance] setIntValue:(int)state forKey:FRESHCHAT_DEFAULTS_AUTH_STATE];
    [[NSNotificationCenter defaultCenter] postNotificationName:JWT_EVENT object:nil];
    [FCLocalNotification post:FRESHCHAT_ACTION_USER_ACTIONS info:@{@"user_action" :@"ID_TOKEN_STATUS_CHANGED"}];
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

    if([[FCJWTAuthValidator sharedInstance] getDefaultJWTState]  == TOKEN_VALID ||
       [[FCJWTAuthValidator sharedInstance] getDefaultJWTState] == TOKEN_INVALID ||
       [[FCJWTAuthValidator sharedInstance] getDefaultJWTState] == TOKEN_NOT_SET) {
        return [[FCJWTAuthValidator sharedInstance] getUiActionForTokenState: [[FCJWTAuthValidator sharedInstance] getDefaultJWTState]];
    } else if([[FCJWTAuthValidator sharedInstance] getDefaultJWTState] == TOKEN_EXPIRED) {
        if ([FCJWTAuthValidator sharedInstance].prevState == TOKEN_VALID) {
            return SHOW_CONTENT;
        } else {
            return LOADING;
        }
    } else if([[FCJWTAuthValidator sharedInstance] getDefaultJWTState] == TOKEN_NOT_PROCESSED) {
        if([FCJWTAuthValidator sharedInstance].prevState == TOKEN_EXPIRED){
            return SHOW_CONTENT;
        } else {
            return LOADING;
        }
    }
    
    return NO_CHANGE;
}

-(void) resetPrevJWTState {
    [FCJWTAuthValidator sharedInstance].prevState = [[FCJWTAuthValidator sharedInstance] getDefaultJWTState];

}

- (BOOL) canSetStateToNotProcessed {
    return ([[FCJWTAuthValidator sharedInstance] getDefaultJWTState] != TOKEN_VALID && [[FCJWTAuthValidator sharedInstance] getDefaultJWTState] != TOKEN_NOT_SET );
}

- (BOOL) canStartLoadingTimer {
    return (([[FCJWTAuthValidator sharedInstance] getDefaultJWTState] == TOKEN_NOT_SET) || ([[FCJWTAuthValidator sharedInstance] getDefaultJWTState] == TOKEN_EXPIRED));
}



@end
