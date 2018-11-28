//
//  AppDelegate.h
//  Hotline
//
//  Created by AravinthChandran on 9/7/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FreshchatSDK/FreshchatSDK.h"
#import "HotlineConfigStrings.h"
#define STORYBOARD_NAME @"Main"
#define STORYBOARD_IDENTIFIER @"HotlineViewController"
#define SAMPLE_STORYBOARD_CONTROLLER @"SampleController"
#define SAMPLE_DEEPLINK_CONTROLLER @"LinkHandlerVC"
#define IN_APP_BROWSER_STORYBOARD_CONTROLLER @"InAppBrowser"
#define LAUNCH_SAMPLE_CONTROLLER NO
#define LAUNCH_DEEPLINK_CONTROLLER YES


@interface AppDelegate : UIResponder <UIApplicationDelegate>

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UIImage *pickedImage;
-(void)setupRootController;
+(FreshchatUser *)createFreshchatUser;

@end
