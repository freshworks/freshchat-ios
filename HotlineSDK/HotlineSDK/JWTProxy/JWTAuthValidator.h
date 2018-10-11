//
//  JWTAuthValidator.h
//  HotlineSDK
//
//  Created by Sanjith Kanagavel on 05/10/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ACTIVE_EVENT @"com.freshchat.jwt.active"
#define JWT_EVENT @"com.freshchat.jwt.event"
#define WAIT_FOR_FIRST_TOKEN_EVENT @"com.freshchat.jwt.wft"
#define VERIFICATION_UNDER_PROGRESS_EVENT @"com.freshchat.jwt.vup"
#define WAITING_FOR_REFRESH_TOKEN_EVENT @"com.freshchat.jwt.wrt"
#define TOKEN_VERIFICATION_FAILED_EVENT @"com.freshchat.jwt.tvf"

enum JWT_STATE {
    NONE = 0,
    ACTIVE = 1,
    WAIT_FOR_FIRST_TOKEN = 2,
    VERIFICATION_UNDER_PROGRESS = 3,
    WAITING_FOR_REFRESH_TOKEN = 4,
    TOKEN_VERIFICATION_FAILED = 5
};

enum JWT_UI_STATE {
    LOADING = 1,
    SHOW_ALERT = 2,
    SHOW_CONTENT = 3,
    NO_CHANGE = 4
};


@interface JWTAuthValidator: NSObject

+ (instancetype) sharedInstance;
- (void)fireChange : (enum JWT_STATE) stateChange;

- (enum JWT_UI_STATE) getUiActionForTokenState: (enum JWT_STATE) apiState;
- (enum JWT_UI_STATE) getUiActionForTransition;


@property (strong, nonatomic) NSTimer* timer;
@property (assign, nonatomic) enum JWT_STATE currState;
@property (assign, nonatomic) enum JWT_STATE prevState;


@end
