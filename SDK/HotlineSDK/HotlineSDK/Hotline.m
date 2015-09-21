//
//  Hotline.m
//  Konotor
//
//  Created by AravinthChandran on 9/7/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "Hotline.h"
#import "KonotorFeedbackScreen.h"
#import "KonotorEventHandler.h"

@implementation Hotline

+(void)showFeedbackScreen{
    [KonotorFeedbackScreen showFeedbackScreen];
}

+(void)setSecretKey:(NSString *)key{
    [Konotor setSecretKey:key];
}

+(void)InitWithAppID:(NSString *)AppID AppKey:(NSString *)AppKey withDelegate:(id)delegate{
    if (delegate) {
        [Konotor InitWithAppID:AppID AppKey:AppKey withDelegate:delegate];
    }else{
        [Konotor InitWithAppID:AppID AppKey:AppKey withDelegate:[KonotorEventHandler sharedInstance]];
    }
}

+(void)setUnreadWelcomeMessage:(NSString *)text{
    [Konotor setUnreadWelcomeMessage:text];
}

+(void)presentSolutions:(UIViewController *)controller{
    
}

@end
