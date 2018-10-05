//
//  JWTAuthValidator.h
//  HotlineSDK
//
//  Created by Sanjith Kanagavel on 05/10/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ACTIVE_EVENT @"com.freshchat.jwt.active"
#define WAIT_FOR_FIRST_TOKEN_EVENT @"com.freshchat.jwt.wft"
#define VERIFICATION_UNDER_PROGRESS_EVENT @"com.freshchat.jwt.vup"
#define WAITING_FOR_REFRESH_TOKEN_EVENT @"com.freshchat.jwt.wrt"
#define TOKEN_VERIFICATION_FAILED_EVENT @"com.freshchat.jwt.tvf"

enum API_STATES {
    ACTIVE = 1,
    WAIT_FOR_FIRST_TOKEN = 2,
    VERIFICATION_UNDER_PROGRESS = 3,
    WAITING_FOR_REFRESH_TOKEN = 4,
    TOKEN_VERIFICATION_FAILED = 5
};


@interface JWTAuthValidator: NSObject

+ (instancetype) sharedInstance;
+ (void) postNotification:(enum API_STATES)state;
@property (strong, nonatomic) NSTimer* timer;
@property (assign, nonatomic) enum API_STATES state;

@end
