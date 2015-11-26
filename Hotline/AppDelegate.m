//
//  AppDelegate.m
//  Hotline
//
//  Created by AravinthChandran on 9/7/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "AppDelegate.h"
#import "HotlineSDK/Hotline.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self konotorIntegration];
    return YES;
}

-(void)konotorIntegration{
    Hotline *hotlineSDK = [Hotline sharedInstance];
    [hotlineSDK InitWithAppID:@"4a10bd32-f0a5-4ac4-b95e-a88d405d0650" AppKey:@"3b649759-435e-4111-a504-c02335b9f999" withDelegate:nil];
    [Hotline setUnreadWelcomeMessage:@"Welcome to Whatsfab! Get 10% off on your first purchase using the special code NOOB20. \nWe're here if you have any questions!"];
}

@end