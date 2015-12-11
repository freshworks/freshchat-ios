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
    HotlineConfig *config = [[HotlineConfig alloc]initWithDomain:@"hline.pagekite.me" withAppID:@"0e611e03-572a-4c49-82a9-e63ae6a3758e"
                                                       andAppKey:@"be346b63-59d7-4cbc-9a47-f3a01e35f093"];
    [[Hotline sharedInstance]initWithConfig:config];
}

@end