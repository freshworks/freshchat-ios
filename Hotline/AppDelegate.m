//
//  AppDelegate.m
//  Hotline
//
//  Created by AravinthChandran on 9/7/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "AppDelegate.h"
#import "FreshdeskSDK/Mobihelp.h"
#import "HotlineSDK/Hotline.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self konotorIntegration];
    return YES;
}

-(void)rexinc{
    MobihelpConfig *config = [[MobihelpConfig alloc]initWithDomain:@"rexinc.freshdesk.com" withAppKey:@"arvchz-2-0596aef1ff21fb369717fbb1991c557c" andAppSecret:@"3389816b76ae70737910a9f57f4b25390dff21a4"];
    config.feedbackType = FEEDBACK_TYPE_NAME_REQUIRED_AND_EMAIL_OPTIONAL;
    config.enableAutoReply = YES;
    config.enableEnhancedPrivacy = NO;
    config.appStoreId=@"id849713306";
    Mobihelp *mobihelp = [Mobihelp sharedInstance];
    [mobihelp initWithConfig:config];
}

-(void)konotorIntegration{
    Hotline *hotlineSDK = [Hotline sharedInstance];
    [hotlineSDK InitWithAppID:@"0e611e03-572a-4c49-82a9-e63ae6a3758e" AppKey:@"be346b63-59d7-4cbc-9a47-f3a01e35f093" withDelegate:nil];
    [Hotline setSecretKey:@"468f1bb16e270cdbd73f7ef9054b9a8d"];
    [Hotline setUnreadWelcomeMessage:@"Welcome to Whatsfab! Get 10% off on your first purchase using the special code NOOB20. \nWe're here if you have any questions!"];
}

@end
