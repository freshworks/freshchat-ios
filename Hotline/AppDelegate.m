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
    [hotlineSDK InitWithAppID:@"b120cc8a-3585-4f46-b89f-6c5f54c0c7f2" AppKey:@"818ce610-019c-4049-8c91-808669978c7a" withDelegate:nil];
}

@end