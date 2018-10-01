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
#import "Hotline_Demo-Swift.h"


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
    if(PUSH_ENABLED){
        [self registerAppForNotifications];
    }
    [self hotlineIntegration];
    if (LAUNCH_SAMPLE_CONTROLLERT) {
        [self launchSampleController];
    } else {
        [self setupRootController];
    }
    /*[[Freshchat sharedInstance]resetUserWithCompletion:^{
        [[Freshchat sharedInstance] setUser:[AppDelegate createFreshchatUser]];
    }];*/
    if ([[Freshchat sharedInstance]isFreshchatNotification:launchOptions]) {
        [[Freshchat sharedInstance]handleRemoteNotification:launchOptions andAppstate:application.applicationState];
    }
    [Fabric with:@[[Crashlytics class]]];
    return YES;
    
}

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    #if ENABLE_RTL_RUNTIME
        [L102Localizer DoTheMagic];
        if([[L102Language currentAppleLanguage] isEqualToString:@"ar"]) {
            UIView.appearance.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        } else {
            UIView.appearance.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        }
        NSLog(@":::Current Language : %@", [L102Language currentAppleLanguage]);
    #endif
    return true;
}

-(void)launchSampleController {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:SAMPLE_STORYBOARD_CONTROLLER bundle:nil];
    ViewController *mainController = [sb instantiateViewControllerWithIdentifier:SAMPLE_STORYBOARD_CONTROLLER];
    [self.window setRootViewController:mainController];
    [self.window makeKeyAndVisible];
    //[[Freshchat sharedInstance] resetUserWithCompletion:nil];
}

-(void)setupRootController{
    
    Freshchat *freshchatSDK = [Freshchat sharedInstance];
    _rootController1 = [freshchatSDK getConversationsControllerForEmbed];
    _channelsController = [[UINavigationController alloc]initWithRootViewController:_rootController1];
    
    BOOL isTabViewPreferred = YES;
    
    if (isTabViewPreferred) {
        ConversationOptions *convOptions = [[ConversationOptions alloc] init];
        [convOptions filterByTags:@[@"wow",@"wow1"] withTitle:@"Wow Conv[App]"];
        NSArray *arr = @[@"wow",@"wow1"];
        NSArray *contactUsTagsArray = @[@"wow"];
        FAQOptions *faqOptions = [FAQOptions new];
        faqOptions.showFaqCategoriesAsGrid = NO;
        faqOptions.showContactUsOnFaqScreens = YES;
        
        [faqOptions filterContactUsByTags:contactUsTagsArray withTitle:@"Wow ContactUS"];
        [faqOptions filterByTags:arr withTitle:@"Wow Articles[App]" andType: ARTICLE];
        UINavigationController* faqControllerOption = [[UINavigationController alloc]initWithRootViewController:[[Freshchat sharedInstance]getFAQsControllerForEmbedWithOptions:faqOptions]];
        UINavigationController* convControllerOption = [[UINavigationController alloc]initWithRootViewController:[[Freshchat sharedInstance]getConversationsControllerForEmbedWithOptions:convOptions]];
        UIStoryboard *sb = [UIStoryboard storyboardWithName:STORYBOARD_NAME bundle:nil];
        
        ViewController *mainController = [sb instantiateViewControllerWithIdentifier:STORYBOARD_IDENTIFIER];
        UINavigationController *mainNavigationController = [[UINavigationController alloc] initWithRootViewController:mainController];
        UINavigationController *FAQController = [[UINavigationController alloc]initWithRootViewController:
                                                 [freshchatSDK getFAQsControllerForEmbed]];
        
        mainController.title = @"Freshchat";
        _channelsController.title = @"Channels";
        FAQController.title = @"FAQs";
        faqControllerOption.title = @"FQAsWithOptions";
        convControllerOption.title = @"ConvWithOptions";

        UITabBarController* tabBarController=[[UITabBarController alloc] init];
        [tabBarController setViewControllers:@[mainNavigationController, FAQController,faqControllerOption, _channelsController,convControllerOption]];
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

+(FreshchatUser *)createFreshchatUser{
    FreshchatUser *user = [FreshchatUser sharedInstance];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterFullStyle];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm";
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    user.firstName = [@"User - " stringByAppendingString:dateString];
    user.lastName = @"Ohsumi1234";
    user.firstName = @"Muthu";
    user.lastName = @"K";
    user.email = @"muthu@freshdesk.com";
    user.phoneNumber = @"9898989898";
    user.phoneCountryCode = @"+91";
    /*
    user.externalID = @"SanjithNew11";
    user.restoreID = @"4c03d5f2-6c87-435d-a63f-fa8a040fe832";
     */
    /*
    user.externalID = @"SanjithNew10";
    user.restoreID = @"ab64445d-fca2-455c-ac4f-1406565ea322";
    */
    /*
     user.externalID = @"SanjithNew10";
     user.restoreID = @"0b3af9c5-f1c6-4225-adcf-e7c99fbdbab7";
    */
    return user;
    
}


-(void)hotlineIntegration{
    
    FreshchatConfig *config = [[FreshchatConfig alloc]initWithAppID:HOTLINE_APP_ID andAppKey:HOTLINE_APP_KEY];
    config.domain = HOTLINE_DOMAIN;
    //config.voiceMessagingEnabled = NO;
//       config.appID = @"7baba8ff-d18e-4e20-a096-3ea5be53ba67";
//       config.appKey = @"72645c38-b738-491e-94b4-0eb0b9e98e2f";
//       config.domain = @"mobihelp.ngrok.io";
//    
//      config.domain = @"satheeshjm.pagekite.me";
//      config.appID = @"0e611e03-572a-4c49-82a9-e63ae6a3758e";
//      config.appKey = @"be346b63-59d7-4cbc-9a47-f3a01e35f093";
    
//    config.domain = @"mr.white.konotor.com";
//    config.appID = @"92124c8f-bd1a-4362-a390-72e76b8c55644-f128-4389-888f-716b3f628f67ef7125c";
//    config.appKey = @"c4cdef27-ff3d-4d01-a0af-7e3c4cde4fc6";

    config.teamMemberInfoVisible = YES;
    
    [Freshchat sharedInstance].shouldInteractWithURL = ^BOOL(NSURL * url) {
        NSLog(@"%@",url.description);        
        return FALSE;
    };
    
    //config.pictureMessagingEnabled = YES;
    config.cameraCaptureEnabled = YES;
    if(![FreshchatUser sharedInstance].firstName){
        //[[Freshchat sharedInstance] setUser:[AppDelegate createFreshchatUser]];
    }
    config.cameraCaptureEnabled = YES;
    config.gallerySelectionEnabled = YES;
    NSLog(@"Current User :Name  %@ %@", [FreshchatUser sharedInstance].firstName,[FreshchatUser sharedInstance].lastName);
    NSLog(@"Current User :Identifier  %@ restoreID: %@", [FreshchatUser sharedInstance].externalID, [FreshchatUser sharedInstance].restoreID);
    [[Freshchat sharedInstance]initWithConfig:config];
    
    //if(![FreshchatUser sharedInstance].restoreID)
    //{
        //[[Freshchat sharedInstance] setUser:[AppDelegate createFreshchatUser]];
    //}
    
    //[[Freshchat sharedInstance] setUserProperties:@{ @"SDK Version" : [Freshchat SDKVersion] }];
    
    

    [[Freshchat sharedInstance]unreadCountWithCompletion:^(NSInteger count) {
        NSLog(@"Unread count (Async) : %d", (int)count);
    }];
    
    [[NSNotificationCenter defaultCenter]addObserverForName:FRESHCHAT_USER_RESTORE_ID_GENERATED object:nil queue:nil usingBlock:^(NSNotification *note) {
        NSLog(@"Current User :Restore-ID  %@", [FreshchatUser sharedInstance].restoreID);
        NSLog(@"Current User :Identifier  %@", [FreshchatUser sharedInstance].externalID);
        /*
         Sanjith.kanagavel+web@freshworks.com/kangavel
         Working Combination : 79bc06ed-e3f8-4b18-a03d-a92a178d0d48 / NewUser123
         Working Combination : b8c55644-f128-4389-888f-716b3f628f67 / NewUser123
         Wrong Combination : 79bc06ed-e3f8-4b18-a03d-a92a178d0d41 / NewUser123
         */
    }];
}

-(void)registerAppForNotifications {
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
    [[Freshchat sharedInstance] setPushRegistrationToken:devToken];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (error.code != 3010) { //Checks for simulator
        NSLog(@"Device failed to register remote notification  %@", error);
    }
}

- (void) application:(UIApplication *)app didReceiveRemoteNotification:(NSDictionary *)info{
    NSLog(@"Push recieved :%@", info);
    

    
    if ([[Freshchat sharedInstance]isFreshchatNotification:info]) {
        [[Freshchat sharedInstance]handleRemoteNotification:info andAppstate:app.applicationState];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application{
    [[Freshchat sharedInstance]unreadCountWithCompletion:^(NSInteger count) {
        NSLog(@"Unread count  %ld", (long)count);
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
