//
//  HLNotificationHandler.m
//  HotlineSDK
//
//  Created by Harish Kumar on 05/04/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FCNotificationHandler.h"
#import "FCSecureStore.h"
#import "FCChannels.h"
#import "FCMacros.h"
#import "HotlineAppState.h"
#import "FCChannelViewController.h"
#import "FCMessageController.h"
#import "FCContainerController.h"
#import "FCMemLogger.h"
#import "FCMessageServices.h"
#import "FCUtilities.h"

//New Enum decl. adoption
typedef NS_ENUM(NSInteger, FCNotifType) {
    Message = 1,
    Marketing = 2,
    CSAT = 3
};

@interface FCNotificationHandler ()

@property (nonatomic, strong) FCNotificationBanner *banner;
@property (nonatomic, strong) NSNumber *marketingID;

@end

@implementation FCNotificationHandler

- (instancetype)init{
    self = [super init];
    if (self) {
        self.banner = [FCNotificationBanner sharedInstance];
        self.banner.delegate = self;
    }
    return self;
}

+(BOOL)isFreshchatNotification:(NSDictionary *)info{
    NSDictionary *payload = [FCNotificationHandler getPayloadFromNotificationInfo:info];
    return ([payload[@"source"] isEqualToString:FRESHCHAT_NOTIFICATION_PAYLOAD_SOURCE_USER]);
}

-(void)handleNotification:(NSDictionary *)info appState:(UIApplicationState)appState{
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            NSDictionary *payload = [FCNotificationHandler getPayloadFromNotificationInfo:info];
            NSNumber *channelID = nil;
            NSString *message;
            int notificationType = [[payload objectForKey:FRESHCHAT_NOTIFICATION_PAYLOAD_NOTIF_TYPE] intValue];
            
            if((notificationType < Message) || (notificationType > CSAT)){
                FDLog(@"Unknown notification type!");
                return ;
            }
            
            if((notificationType != Marketing) && !([payload[FRESHCHAT_NOTIFICATION_PAYLOAD_TARGET_USER_ALIAS] isEqualToString:[FCUtilities currentUserAlias]])) {
                return;
            }
            
            if([payload objectForKey:FRESHCHAT_NOTIFICATION_PAYLOAD_CHANNEL_ID]) {
                channelID = @([payload[FRESHCHAT_NOTIFICATION_PAYLOAD_CHANNEL_ID] integerValue]);
            }else{
                return;
            }
            
            self.marketingID = @([payload[FRESHCHAT_NOTIFICATION_PAYLOAD_MARKETING_ID] integerValue]);
        
            if (notificationType == CSAT) {
                message = (trimString([FCUtilities getLocalizedPositiveFeedCSATQues]).length > 0) ? [FCUtilities getLocalizedPositiveFeedCSATQues] : [payload valueForKeyPath:FRESHCHAT_NOTIFICATION_PAYLOAD_MESSAGE];
            }
            else{
                message = [payload valueForKeyPath:FRESHCHAT_NOTIFICATION_PAYLOAD_MESSAGE];
            }
    
            FCChannels *channel = [FCChannels getWithID:channelID inContext:[FCDataManager sharedInstance].mainObjectContext];
            
            enum MessageFetchType fetchType = channel ? FetchMessages : FetchAll;
            
            [FCMessageServices fetchChannelsAndMessagesWithFetchType:fetchType
                                                              source:Notification
                                                          andHandler:^(NSError *error){
                if(!error){
                    NSManagedObjectContext *mContext = [FCDataManager sharedInstance].mainObjectContext;
                    [mContext performBlock:^{
                        @try {
                            FCChannels *ch;
                            if (!channel){
                                ch = [FCChannels getWithID:channelID inContext:mContext];
                            }
                            else {
                                ch = channel;
                            }
                            if(ch){
                                [self handleNotification:ch withMessage:message andState:appState];
                            }
                        }
                        @catch(NSException *exception) {
                            [FCMemLogger sendMessage:exception.description
                                          fromMethod:NSStringFromSelector(_cmd)];
                        }
                    }];
                }
            }];
            
        }
        @catch(NSException *exception){
            [FCMemLogger sendMessage:exception.description fromMethod:NSStringFromSelector(_cmd)];
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
                    FCMemLogger *memlogger = [[FCMemLogger alloc]init];
                    [memlogger addMessage:[NSString stringWithFormat:@"payload for key UIApplicationLaunchOptionsRemoteNotificationKey -> %@ ",
                                           launchOptions]];
                    [memlogger upload];
                }
            }else{
                payload = info;
            }
        }else{
            FCMemLogger *memlogger = [[FCMemLogger alloc]init];
            [memlogger addMessage:[NSString stringWithFormat:@"Invalid push notification payload -> %@ ", info]];
            [memlogger upload];
        }
    }
    
    return payload;
}

-(void) showActiveStateNotificationBanner :(FCChannels *)channel withMessage:(NSString *)message{
    //Check active state because HLMessageServices can run in background and call this.
    dispatch_async(dispatch_get_main_queue(), ^{
        if([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive){
            return;
        }
    });
    BOOL bannerEnabled = [[FCSecureStore sharedInstance] boolValueForKey:HOTLINE_DEFAULTS_SHOW_NOTIFICATION_BANNER];
    if(bannerEnabled && ![channel isActiveChannel]){
        [self.banner setMessage:message];
        [self.banner displayBannerWithChannel:channel];
    }
}

- (void) handleNotification :(FCChannels *)channel withMessage:(NSString *)message andState:(UIApplicationState)state{
    if (state == UIApplicationStateInactive) {
        [FCMessageServices markMarketingMessageAsClicked:self.marketingID];
        [self launchMessageControllerOfChannel:channel];
    }
    else {
        [self showActiveStateNotificationBanner:channel withMessage:message];
    }
}

-(void)notificationBanner:(FCNotificationBanner *)banner bannerTapped:(id)sender{
    [FCMessageServices markMarketingMessageAsClicked:self.marketingID];
    [self launchMessageControllerOfChannel:banner.currentChannel];
}

-(void)launchMessageControllerOfChannel:(FCChannels *)channel{
    UIViewController *visibleSDKController = [HotlineAppState sharedInstance].currentVisibleController;
    if (visibleSDKController) {
        if ([visibleSDKController isKindOfClass:[FCChannelViewController class]]) {
            [self pushMessageControllerFrom:visibleSDKController.navigationController withChannel:channel];
        } else if ([visibleSDKController isKindOfClass:[FCMessageController class]]) {
            FCMessageController *msgController = (FCMessageController *)visibleSDKController;
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
        [self presentMessageControllerOn:[FCUtilities topMostController] withChannel:channel];
    }
}

-(void)pushMessageControllerFrom:(UINavigationController *)controller withChannel:(FCChannels *)channel{
    FCMessageController *messageController = [[FCMessageController alloc]initWithChannelID:channel.channelID andPresentModally:NO fromNotification:YES];
    [messageController setConversationOptions:[ConversationOptions new]];
    FCContainerController *container = [[FCContainerController alloc]initWithController:messageController andEmbed:NO];
    [controller pushViewController:container animated:YES];
}

-(void)presentMessageControllerOn:(UIViewController *)controller withChannel:(FCChannels *)channel{
    FCMessageController *messageController = [[FCMessageController alloc]initWithChannelID:channel.channelID andPresentModally:YES fromNotification:YES];
    [messageController setConversationOptions:[ConversationOptions new]];
    FCContainerController *containerController = [[FCContainerController alloc]initWithController:messageController andEmbed:NO];
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
