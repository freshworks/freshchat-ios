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
    [self hotlineIntegration];
    [self registerAppForNotifications];
    [self handleNotification:launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]];
    return YES;
}

-(void)hotlineIntegration{
    HotlineConfig *config = [[HotlineConfig alloc]initWithDomain:@"hline.pagekite.me" withAppID:@"0e611e03-572a-4c49-82a9-e63ae6a3758e"
                                                       andAppKey:@"be346b63-59d7-4cbc-9a47-f3a01e35f093"];
    HotlineUser *user = [[HotlineUser alloc]init];
    user.userName = @"JonSnow";
    user.emailAddress = @"snow@ios";
    user.phoneNumber = @"9898989898";
    user.externalID = @"winterfell";
    [[Hotline sharedInstance]initWithConfig:config andUser:user];
    [[Hotline sharedInstance]setCustomUserPropertyForKey:@"Sigil" withValue:@"wolf"];
}

-(void)registerAppForNotifications{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }else{
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes: (UIRemoteNotificationTypeNewsstandContentAvailability| UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
}

-(void)handleNotification:(NSDictionary *)info {
    if ([info[@"source"] isEqualToString:@"konotor"]) {
        [[Hotline sharedInstance] handleRemoteNotification:info];
    }
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
    NSLog(@"Registered Device Token  %@", devToken);
    NSLog(@"is app registered for notifications :: %d" , [[UIApplication sharedApplication] isRegisteredForRemoteNotifications]);
    [[Hotline sharedInstance] addDeviceToken:devToken];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Failed to register remote notification  %@", error);
}

- (void) application:(UIApplication *)app didReceiveRemoteNotification:(NSDictionary *)info{
    [self handleNotification:info];
}

- (void)applicationDidBecomeActive:(UIApplication *)application{
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

@end