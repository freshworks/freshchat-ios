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
#import "FDMemLogger.h"
#import "HLMessageServices.h"
#import "FDUtilities.h"

@interface HLNotificationHandler ()

@property (nonatomic, strong) FDNotificationBanner *banner;
@property (nonatomic, strong) NSNumber *marketingID;

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

+(BOOL)isFreshchatNotification:(NSDictionary *)info{
    NSDictionary *payload = [HLNotificationHandler getPayloadFromNotificationInfo:info];
    return ([payload[@"source"] isEqualToString:FRESHCHAT_NOTIFICATION_PAYLOAD_SOURCE_USER]);
}

-(void)handleNotification:(NSDictionary *)info appState:(UIApplicationState)appState{
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            
            NSDictionary *payload = [HLNotificationHandler getPayloadFromNotificationInfo:info];
            // Check if current user alias and payload user alias are same
            if(![payload[FRESHCHAT_NOTIFICATION_PAYLOAD_TARGET_USER_ALIAS] isEqualToString:[FDUtilities currentUserAlias]]){
                return;
            }
            NSNumber *channelID = nil;
            
            if ([payload objectForKey:FRESHCHAT_NOTIFICATION_PAYLOAD_CHANNEL_ID]) {
                channelID = @([payload[FRESHCHAT_NOTIFICATION_PAYLOAD_CHANNEL_ID] integerValue]);
            }else{
                return;
            }
            
            if ([payload objectForKey:FRESHCHAT_NOTIFICATION_PAYLOAD_MARKETING_ID]) {
                self.marketingID = @([payload[FRESHCHAT_NOTIFICATION_PAYLOAD_MARKETING_ID] integerValue]);
            }
            
            NSString *message = [payload valueForKeyPath:@"aps.alert.body"];
            
            HLChannel *channel = [HLChannel getWithID:channelID inContext:[KonotorDataManager sharedInstance].mainObjectContext];
            
            enum MessageFetchType fetchType = channel ? FetchMessages : FetchAll;
            
            [HLMessageServices fetchChannelsAndMessagesWithFetchType:fetchType
                                                              source:Notification
                                                          andHandler:^(NSError *error){
                if(!error){
                    NSManagedObjectContext *mContext = [KonotorDataManager sharedInstance].mainObjectContext;
                    [mContext performBlock:^{
                        @try {
                            HLChannel *ch;
                            if (!channel){
                                ch = [HLChannel getWithID:channelID inContext:mContext];
                            }
                            else {
                                ch = channel;
                            }
                            if(ch){
                                [self handleNotification:ch withMessage:message andState:appState];
                            }
                        }
                        @catch(NSException *exception) {
                            [FDMemLogger sendMessage:exception.description
                                          fromMethod:NSStringFromSelector(_cmd)];
                        }
                    }];
                }
            }];
            
        }
        @catch(NSException *exception){
            [FDMemLogger sendMessage:exception.description fromMethod:NSStringFromSelector(_cmd)];
        }
    });
}

+(NSDictionary *)getPayloadFromNotificationInfo:(NSDictionary *)info{
    NSDictionary *payload = @{};
    if (info) {
        if ([info isKindOfClass:[NSDictionary class]]) {
            NSDictionary *launchOptions = info[@"UIApplicationLaunchOptionsRemoteNotificationKey"];
            if (launchOptions) {
                if ([launchOptions isKindOfClass:[NSDictionary class]]) {
                    payload = launchOptions;
                }else{
                    FDMemLogger *memlogger = [[FDMemLogger alloc]init];
                    [memlogger addMessage:[NSString stringWithFormat:@"payload for key UIApplicationLaunchOptionsRemoteNotificationKey -> %@ ",
                                           launchOptions]];
                    [memlogger upload];
                }
            }else{
                payload = info;
            }
        }else{
            FDMemLogger *memlogger = [[FDMemLogger alloc]init];
            [memlogger addMessage:[NSString stringWithFormat:@"Invalid push notification payload -> %@ ", info]];
            [memlogger upload];
        }
    }
    
    return payload;
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
    }
}

- (void) handleNotification :(HLChannel *)channel withMessage:(NSString *)message andState:(UIApplicationState)state{
    if (state == UIApplicationStateInactive) {
        [HLMessageServices markMarketingMessageAsClicked:self.marketingID];
        [self launchMessageControllerOfChannel:channel];
    }
    else {
        [self showActiveStateNotificationBanner:channel withMessage:message];
    }
}

-(void)notificationBanner:(FDNotificationBanner *)banner bannerTapped:(id)sender{
    [HLMessageServices markMarketingMessageAsClicked:self.marketingID];
    [self launchMessageControllerOfChannel:banner.currentChannel];
}

-(void)launchMessageControllerOfChannel:(HLChannel *)channel{
    UIViewController *visibleSDKController = [HotlineAppState sharedInstance].currentVisibleController;
    if (visibleSDKController) {
        if ([visibleSDKController isKindOfClass:[HLChannelViewController class]]) {
            [self pushMessageControllerFrom:visibleSDKController.navigationController withChannel:channel];
        } else if ([visibleSDKController isKindOfClass:[FDMessageController class]]) {
            FDMessageController *msgController = (FDMessageController *)visibleSDKController;
            if (![channel isActiveChannel]) {
                if (msgController.isModal) {
                        [self presentMessageControllerOn:visibleSDKController withChannel:channel];
                }else{
                    UINavigationController *navController = msgController.navigationController;
                    [navController popViewControllerAnimated:NO];
                    [self pushMessageControllerFrom:navController withChannel:channel];
                }
            }
        }else {
            [self presentMessageControllerOn:visibleSDKController withChannel:channel];
        }
        
    }else{
        [self presentMessageControllerOn:[FDUtilities topMostController] withChannel:channel];
    }
}

-(void)pushMessageControllerFrom:(UINavigationController *)controller withChannel:(HLChannel *)channel{
    FDMessageController *conversationController = [[FDMessageController alloc]initWithChannelID:channel.channelID andPresentModally:NO fromNotification:YES];
    HLContainerController *container = [[HLContainerController alloc]initWithController:conversationController andEmbed:NO];
    [controller pushViewController:container animated:YES];
}

-(void)presentMessageControllerOn:(UIViewController *)controller withChannel:(HLChannel *)channel{
    FDMessageController *messageController = [[FDMessageController alloc]initWithChannelID:channel.channelID andPresentModally:YES fromNotification:YES];
    HLContainerController *containerController = [[HLContainerController alloc]initWithController:messageController andEmbed:NO];
    UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:containerController];
    [controller presentViewController:navigationController animated:YES completion:nil];
}


+(BOOL) areNotificationsEnabled{
#if (TARGET_OS_SIMULATOR)
    return NO;
#else
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
#endif
}

@end
