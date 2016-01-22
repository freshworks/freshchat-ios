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
    return YES;
}

-(void)hotlineIntegration{
    HotlineConfig *config = [[HotlineConfig alloc]initWithDomain:@"hline.pagekite.me" withAppID:@"0e611e03-572a-4c49-82a9-e63ae6a3758e"
                                                       andAppKey:@"be346b63-59d7-4cbc-9a47-f3a01e35f093"];
    
    config.voiceMessagingEnabled = YES;
    config.pictureMessagingEnabled = YES;
    
    HotlineUser *user = [HotlineUser sharedInstance];
    user.userName = @"Sid";
    user.emailAddress = @"sid@freshdesk.com";
    user.phoneNumber = @"9898989898";
    [[Hotline sharedInstance]initWithConfig:config andUser:user];
    [[Hotline sharedInstance]setCustomUserPropertyForKey:@"CustomerID" withValue:@"10231023"];
    [Hotline sharedInstance].displaySolutionsAsGrid = YES;
    NSLog(@"Unread messages count :%ld", [[Hotline sharedInstance]unreadCount]);
}

-(void)registerAppForNotifications{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }else{
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes: (UIRemoteNotificationTypeNewsstandContentAvailability| UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
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
    if ([[Hotline sharedInstance]isHotlineNotification:info]) {
        UIViewController *rootController = [[UIApplication sharedApplication] keyWindow].rootViewController;
        [[Hotline sharedInstance]handleRemoteNotification:info withController:nil];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application{
    NSInteger unreadCount = [[Hotline sharedInstance]unreadCount];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:unreadCount];
}

/* 
 supported deep link URLs to test:
 hotline://?launch=shoes
 hotline://?launch=cloths
 */
-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    if ([url.scheme isEqualToString:@"hotline"]) {

        if ([url.query isEqualToString:@"launch=shoes"]) {
            NSLog(@"Lauch shoes screen");
        }
        
        if ([url.query isEqualToString:@"launch=cloths"]) {
            NSLog(@"Launch cloths screen");
        }

    }
    
    return YES;
}

@end