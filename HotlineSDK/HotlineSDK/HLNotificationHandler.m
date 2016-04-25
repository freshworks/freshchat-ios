//
//  HLNotificationHandler.m
//  HotlineSDK
//
//  Created by Harish Kumar on 05/04/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "HLNotificationHandler.h"
#import "FDSecureStore.h"
#import "HLChannel.h"
#import "HLMacros.h"
#import "HotlineAppState.h"
#import "HLChannelViewController.h"
#import "FDMessageController.h"
#import "HLContainerController.h"

@interface HLNotificationHandler ()

@property (nonatomic, strong) FDNotificationBanner *banner;

@end

@implementation HLNotificationHandler

- (instancetype)init{
    self = [super init];
    if (self) {
        self.banner = [FDNotificationBanner sharedInstance];
        self.banner.delegate = self;
    }
    return self;
}

-(void) showActiveStateNotificationBanner :(HLChannel *)channel withMessage:(NSString *)message{
    //Check active state because HLMessageServices can run in background and call this.
    if([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive){
        return;
    }
    BOOL bannerEnabled = [[FDSecureStore sharedInstance] boolValueForKey:HOTLINE_DEFAULTS_SHOW_NOTIFICATION_BANNER];
    if(bannerEnabled && ![channel isActiveChannel]){
        [self.banner setMessage:message];
        [self.banner displayBannerWithChannel:channel];
        [self.banner adjustPadding];
    }
}

- (void) handleNotification :(HLChannel *)channel withMessage:(NSString *)message andState:(UIApplicationState)state{
    if (state == UIApplicationStateInactive) {
        [self launchMessageControllerOfChannel:channel];
    }
    else {
        [self showActiveStateNotificationBanner:channel withMessage:message];
    }
}

-(void)notificationBanner:(FDNotificationBanner *)banner bannerTapped:(id)sender{
    [self launchMessageControllerOfChannel:banner.currentChannel];
}

-(void)launchMessageControllerOfChannel:(HLChannel *)channel{
    UIViewController *visibleSDKController = [HotlineAppState sharedInstance].currentVisibleController;
    if (visibleSDKController) {
        if ([visibleSDKController isKindOfClass:[HLChannelViewController class]]) {
            [self pushMessageControllerFrom:visibleSDKController.navigationController withChannel:channel];
        } else if ([visibleSDKController isKindOfClass:[FDMessageController class]]) {
            FDMessageController *msgController = (FDMessageController *)visibleSDKController;
            if (msgController.isModal) {
                if (![channel isActiveChannel]) {
                    [self presentMessageControllerOn:visibleSDKController withChannel:channel];
                }
            }else{
                UINavigationController *navController = msgController.navigationController;
                [navController popViewControllerAnimated:NO];
                [self pushMessageControllerFrom:navController withChannel:channel];
            }
        }else {
            [self presentMessageControllerOn:visibleSDKController withChannel:channel];
        }
        
    }else{
        [self presentMessageControllerOn:[self topMostController] withChannel:channel];
    }
}

-(UIViewController*) topMostController {
    UIViewController *topController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}

-(void)pushMessageControllerFrom:(UINavigationController *)controller withChannel:(HLChannel *)channel{
    FDMessageController *conversationController = [[FDMessageController alloc]initWithChannel:channel andPresentModally:NO];
    HLContainerController *container = [[HLContainerController alloc]initWithController:conversationController andEmbed:NO];
    [controller pushViewController:container animated:YES];
}

-(void)presentMessageControllerOn:(UIViewController *)controller withChannel:(HLChannel *)channel{
    FDMessageController *messageController = [[FDMessageController alloc]initWithChannel:channel andPresentModally:YES];
    HLContainerController *containerController = [[HLContainerController alloc]initWithController:messageController andEmbed:NO];
    UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:containerController];
    [controller presentViewController:navigationController animated:YES completion:nil];
}


+(BOOL) areNotificationsEnabled{
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(currentUserNotificationSettings)]){
        UIUserNotificationSettings *noticationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        if (!noticationSettings || (noticationSettings.types == UIUserNotificationTypeNone)) {
            return NO;
        }
        return YES;
    }
    UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    if (types & UIRemoteNotificationTypeAlert){
        return YES;
    }
    return NO;
}

@end
