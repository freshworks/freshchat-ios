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
#import "HotlineConfigStrings.h"

@interface AppDelegate ()

@property (nonatomic, strong)UIViewController *rootController;
@property (nonatomic, strong)UIViewController *rootController1;
@property (nonatomic, strong)UINavigationController *channelsController;

@end

@implementation AppDelegate

#define STORYBOARD_NAME @"Main"
#define STORYBOARD_IDENTIFIER @"HotlineViewController"
#define SAMPLE_STORYBOARD_CONTROLLER @"SampleController"
#define LAUNCH_SAMPLE_CONTROLLERT NO

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self registerAppForNotifications];
    [self hotlineIntegration];
    if (LAUNCH_SAMPLE_CONTROLLERT) {
        [self launchSampleController];
    } else {
        [self setupRootController];
    }
    /*[[Hotline sharedInstance]clearUserDataWithCompletion:^{
        [[Hotline sharedInstance] updateUser:[AppDelegate createHotlineUser]];
    }];*/
    if ([[Hotline sharedInstance]isHotlineNotification:launchOptions]) {
        [[Hotline sharedInstance]handleRemoteNotification:launchOptions andAppstate:application.applicationState];
    }
    [Fabric with:@[[Crashlytics class]]];
    return YES;
    
}


-(void)launchSampleController {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:SAMPLE_STORYBOARD_CONTROLLER bundle:nil];
    ViewController *mainController = [sb instantiateViewControllerWithIdentifier:SAMPLE_STORYBOARD_CONTROLLER];
    [self.window setRootViewController:mainController];
    [self.window makeKeyAndVisible];
    //[[Hotline sharedInstance] clearUserDataWithCompletion:nil];
}

-(void)setupRootController{
    
    Hotline *hotlineSDK = [Hotline sharedInstance];
    _rootController1 = [hotlineSDK getConversationsControllerForEmbed];
    _channelsController = [[UINavigationController alloc]initWithRootViewController:_rootController1];
    
    BOOL isTabViewPreferred = YES;
    
    if (isTabViewPreferred) {
        ConversationOptions *convOptions = [[ConversationOptions alloc] init];
        [convOptions filterByTags:@[@"sanjith"] withTitle:@"Sanjith Conversatios"];
        NSArray *arr = @[@"yoyo"];
        NSArray *contactUsTagsArray = @[@"yoyo"];
        FAQOptions *faqOptions = [FAQOptions new];
        faqOptions.showFaqCategoriesAsGrid = NO;
        faqOptions.showContactUsOnFaqScreens = YES;
        [faqOptions filterContactUsByTags:contactUsTagsArray withTitle:@"Yoyo ContactUS"];
        [faqOptions filterByTags:arr withTitle:@"Yoyo Articles" andType: ARTICLE];
        UINavigationController* faqControllerOption = [[UINavigationController alloc]initWithRootViewController:[[Hotline sharedInstance]getFAQsControllerForEmbedWithOptions:faqOptions]];
        UINavigationController* convControllerOption = [[UINavigationController alloc]initWithRootViewController:[[Hotline sharedInstance]getConversationsControllerForEmbedWithOptions:convOptions]];
        UIStoryboard *sb = [UIStoryboard storyboardWithName:STORYBOARD_NAME bundle:nil];
        ViewController *mainController = [sb instantiateViewControllerWithIdentifier:STORYBOARD_IDENTIFIER];
        UINavigationController *FAQController = [[UINavigationController alloc]initWithRootViewController:
                                                 [hotlineSDK getFAQsControllerForEmbed]];
        
        mainController.title = @"Hotline";
        _channelsController.title = @"Channels";
        FAQController.title = @"FAQs";
        faqControllerOption.title = @"FQAsWithOptions";
        convControllerOption.title = @"ConvWithOptions";

        UITabBarController* tabBarController=[[UITabBarController alloc] init];
        [tabBarController setViewControllers:@[mainController, FAQController,faqControllerOption, _channelsController,convControllerOption]];
        [tabBarController.tabBar setClipsToBounds:NO];
        [tabBarController.tabBar setTintColor:[UIColor colorWithRed:(0x33/0xFF) green:(0x36/0xFF) blue:(0x45/0xFF) alpha:1.0]];
        [tabBarController.tabBar setBarStyle:UIBarStyleDefault];
        NSArray* items = [tabBarController.tabBar items];
        if(items){
            [[items objectAtIndex:0] setImage:[[UIImage imageNamed:@"tab1Image"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
            [[items objectAtIndex:1] setImage:[[UIImage imageNamed:@"tab2Image"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
            [[items objectAtIndex:2] setImage:[[UIImage imageNamed:@"tab2Image"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
            [[items objectAtIndex:3] setImage:[[UIImage imageNamed:@"tab3Image"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
            [[items objectAtIndex:4] setImage:[[UIImage imageNamed:@"tab3Image"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        }
        
        [self.window setRootViewController:tabBarController];
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
    
    HotlineConfig *config = [[HotlineConfig alloc]initWithAppID:HOTLINE_APP_ID andAppKey:HOTLINE_APP_KEY];
    
    

    config.appID = HOTLINE_APP_ID;
    config.appKey = HOTLINE_APP_KEY;
    config.domain = HOTLINE_DOMAIN;
    config.voiceMessagingEnabled = NO;
//       config.appID = @"7baba8ff-d18e-4e20-a096-3ea5be53ba67";
//       config.appKey = @"72645c38-b738-491e-94b4-0eb0b9e98e2f";
//       config.domain = @"mobihelp.ngrok.io";
//    
//      config.domain = @"satheeshjm.pagekite.me";
//      config.appID = @"0e611e03-572a-4c49-82a9-e63ae6a3758e";
//      config.appKey = @"be346b63-59d7-4cbc-9a47-f3a01e35f093";
    
//    config.domain = @"mr.white.konotor.com";
//    config.appID = @"92124c8f-bd1a-4362-a390-72e76ef7125c";
//    config.appKey = @"c4cdef27-ff3d-4d01-a0af-7e3c4cde4fc6";
    
    config.pictureMessagingEnabled = YES;
    if(![HotlineUser sharedInstance].name){
        [[Hotline sharedInstance] updateUser:[AppDelegate createHotlineUser]];
    }
    
    [[Hotline sharedInstance] updateUserProperties:@{ @"SDK Version" : [Hotline SDKVersion] }];
    
    [[Hotline sharedInstance]initWithConfig:config];

    [[Hotline sharedInstance]unreadCountWithCompletion:^(NSInteger count) {
        NSLog(@"Unread count (Async) : %d", (int)count);
    }];
    
    [[NSNotificationCenter defaultCenter]addObserverForName:HOTLINE_UNREAD_MESSAGE_COUNT object:nil queue:nil usingBlock:^(NSNotification *note) {
        NSLog(@"Unread messages  %@", note.userInfo[@"count"]);
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
        for ( int i=0; i<_channelsController.viewControllers.count ; i++ ) {
            NSLog(@"-->%@\n",NSStringFromClass(_channelsController.viewControllers[i].class));
            for( int j=0 ;j<_channelsController.viewControllers[i].childViewControllers.count ;j++ ) {
                NSLog(@"---->%@\n",NSStringFromClass(_channelsController.viewControllers[i].childViewControllers[j].class));
                if ( i == 1 && j == 0 ) {
                    NSLog(@"---->: FDMEssage controller");
                    UIViewController *vc = _channelsController.viewControllers[i].childViewControllers[j];
                    [[Hotline sharedInstance] updateConversationBannerMessage:[NSString stringWithFormat:@"%i", arc4random() %(100)-1 ]];
                    [vc willMoveToParentViewController:vc.parentViewController];
                }
            }
        }
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application{
    [[Hotline sharedInstance]unreadCountWithCompletion:^(NSInteger count) {
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:count];
    }];
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
