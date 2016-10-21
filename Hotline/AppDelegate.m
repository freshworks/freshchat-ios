//
//  AppDelegate.m
//  Hotline
//
//  Created by AravinthChandran on 9/7/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@interface AppDelegate ()

@property (nonatomic, strong)UIViewController *rootController;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self registerAppForNotifications];
    [self setupRootController];
    [self hotlineIntegration];
    if ([[Hotline sharedInstance]isHotlineNotification:launchOptions]) {
        [[Hotline sharedInstance]handleRemoteNotification:launchOptions andAppstate:application.applicationState];
    }
    NSLog(@"launchoptions :%@", launchOptions);
    [Fabric with:@[[Crashlytics class]]];
    return YES;
}

-(void)setupRootController{
    
    BOOL isTabViewPreferred = YES;

    if (isTabViewPreferred) {
        UIViewController* mainView=[self.window rootViewController];
        [mainView setTitle:@"Order"];
        
        UITabBarController* tabBarController=[[UITabBarController alloc] init];
        
        UINavigationController *FAQController = [[UINavigationController alloc]initWithRootViewController:
                                                        [[Hotline sharedInstance] getFAQsControllerForEmbed]];
        [FAQController setTitle:@"FAQs"];
        
        UIViewController* channelsController = [[UINavigationController alloc]initWithRootViewController:
                                                [[Hotline sharedInstance] getConversationsControllerForEmbed]];
        
        [channelsController setTitle:@"Channels"];
        
        [tabBarController setViewControllers:@[mainView, FAQController, channelsController]];
        [tabBarController.tabBar setClipsToBounds:NO];
        [tabBarController.tabBar setTintColor:[UIColor colorWithRed:(0x33/0xFF) green:(0x36/0xFF) blue:(0x45/0xFF) alpha:1.0]];
        [tabBarController.tabBar setBarStyle:UIBarStyleDefault];
        [self.window setRootViewController:tabBarController];
        NSArray* items = [tabBarController.tabBar items];
        if(items){
            [[items objectAtIndex:0] setImage:[[UIImage imageNamed:@"tab1Image"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
            [[items objectAtIndex:1] setImage:[[UIImage imageNamed:@"tab2Image"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
            [[items objectAtIndex:2] setImage:[[UIImage imageNamed:@"tab3Image"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        }
        [self.window makeKeyAndVisible];
        
    }
}

+(HotlineUser *)createHotlineUser{
    HotlineUser *user = [HotlineUser sharedInstance];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterFullStyle];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm";
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    user.name = [@"User - " stringByAppendingString:dateString];
    user.email = @"user@freshdesk.com";
    user.phoneNumber = @"9898989898";
    user.phoneCountryCode = @"+91";
    return user;
}

-(void)hotlineIntegration{
    HotlineConfig *config = [[HotlineConfig alloc]initWithAppID:@"e3280bde-4696-4bd5-8be7-e7919249bf9a"
                                                       andAppKey:@"9d456296-5f38-45ce-884e-b595f7e6301a"];
    
//    config.appID = @"51590df9-ab7e-4ca7-9a25-b2279bc5cc7c";
//    config.appKey = @"e9021572-383c-4b6f-997e-3fea9d32e2c7";
    
//    config.domain=@"mr.orange.konotor.com";

//    prod 
//    config.appID = @"aa221747-9e28-437f-9297-3336353331eb";
//    config.appKey = @"46cd9572-c6ff-4fcb-ac58-6c61a76e3f81";
//    config.domain = @"app.hotline.io";
    
//      config.domain = @"satheeshjm.pagekite.me";
//      config.appID = @"0e611e03-572a-4c49-82a9-e63ae6a3758e";
//      config.appKey = @"be346b63-59d7-4cbc-9a47-f3a01e35f093";
    
//    config.domain = @"mr.white.konotor.com";
//    config.appID = @"92124c8f-bd1a-4362-a390-72e76ef7125c";
//    config.appKey = @"c4cdef27-ff3d-4d01-a0af-7e3c4cde4fc6";
    
    config.voiceMessagingEnabled = YES;
    config.pictureMessagingEnabled = YES;
    config.pollWhenAppActive = YES;

    if(![HotlineUser sharedInstance].name){
        [[Hotline sharedInstance] updateUser:[AppDelegate createHotlineUser]];
    }
    
    
    [[Hotline sharedInstance] updateUserProperties:@{
                                                     @"Unread messages" : @([[Hotline sharedInstance]unreadCount]).description,
                                                     @"SDK Version" : [Hotline SDKVersion]
                                                     }];
    
    [[Hotline sharedInstance]initWithConfig:config];

    [[Hotline sharedInstance]unreadCountWithCompletion:^(NSInteger count) {
        NSLog(@"Unread count (Async) : %d", (int)count);
    }];
    
    [[NSNotificationCenter defaultCenter]addObserverForName:HOTLINE_UNREAD_MESSAGE_COUNT object:nil queue:nil usingBlock:^(NSNotification *note) {
        NSLog(@"updated unread messages count %@", note.userInfo[@"count"]);
    }];
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
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        NSLog(@"is app registered for notifications :: %d" , [[UIApplication sharedApplication] isRegisteredForRemoteNotifications]);
    }
    [[Hotline sharedInstance] updateDeviceToken:devToken];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (error.code != 3010) { //Checks for simulator
        NSLog(@"Device failed to register remote notification  %@", error);
    }
}

- (void) application:(UIApplication *)app didReceiveRemoteNotification:(NSDictionary *)info{
    NSLog(@"Push recieved :%@", info);
    if ([[Hotline sharedInstance]isHotlineNotification:info]) {
        [[Hotline sharedInstance]handleRemoteNotification:info andAppstate:app.applicationState];
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
