//
//  HLViewController.m
//  HotlineSDK
//
//  Created by Hrishikesh on 05/02/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCViewController.h"
#import "FCTheme.h"
#import "FCMacros.h"
#import "FCBarButtonItem.h"
#import "FCControllerUtils.h"
#import "FCAutolayoutHelper.h"
#import "FCChannelViewController.h"
#import "FCMessageController.h"
#import "FCAttachmentImageController.h"
#import "FCLocalNotification.h"
#import "FCRemoteConfig.h"

@implementation FCViewController : UIViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self postNotifForScreenTransition];
    if (self.navigationController == nil) {
        ALog(@"Warning: Use Hotline controllers inside navigation controller");
    }
    else {
        self.navigationController.navigationBar.barStyle = [[FCTheme sharedInstance]statusBarStyle] == UIStatusBarStyleLightContent ?
                                                                    UIBarStyleBlack : UIBarStyleDefault; // barStyle has a different enum but same values .. so hack to clear the update.
        self.navigationController.navigationBar.tintColor = [[FCTheme sharedInstance] navigationBarButtonColor];
    }
}

- (void) postNotifForScreenTransition {
    if(![[FCRemoteConfig sharedInstance] isUserAuthEnabled]) return;
    if([self.class isEqual:[FCChannelViewController class]] || [self.class isEqual:[FCMessageController class]] || [self.class isEqual:[FCAttachmentImageController class]]){
        [FCLocalNotification post:FRESHCHAT_ACTION_USER_ACTIONS info:@{@"user_action" :@"SCREEN_TRANSITION"}];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [FCControllerUtils configureGestureDelegate:[self gestureDelegate] forController:self withEmbedded:self.embedded];
}

-(UIViewController<UIGestureRecognizerDelegate> *) gestureDelegate {
    return nil;
}

-(void)configureBackButton{
    [FCControllerUtils configureBackButtonForController:self withEmbedded:self.embedded];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return [[FCTheme sharedInstance]statusBarStyle];
}

@end
