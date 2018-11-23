//
//  HLNotificationHandler.h
//  HotlineSDK
//
//  Created by Harish Kumar on 05/04/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FCNotificationBanner.h"

#define FRESHCHAT_NOTIFICATION_PAYLOAD_CHANNEL_ID @"channel_id"
#define FRESHCHAT_NOTIFICATION_PAYLOAD_CONV_ID @"conv_id"
#define FRESHCHAT_NOTIFICATION_PAYLOAD_MARKETING_ID @"marketing_id"
#define FRESHCHAT_NOTIFICATION_PAYLOAD_SOURCE_USER @"freshchat_user"
#define FRESHCHAT_NOTIFICATION_PAYLOAD_TARGET_USER_ALIAS @"target_user_alias"
#define FRESHCHAT_NOTIFICATION_PAYLOAD_NOTIF_TYPE @"notif_type"
#define FRESHCHAT_NOTIFICATION_PAYLOAD_MESSAGE @"aps.alert.body"

@interface FCNotificationHandler : NSObject<FDNotificationBannerDelegate>

+(BOOL)isFreshchatNotification:(NSDictionary *)info;
+(NSString *)getChannelIDFromNotification:(NSDictionary *)info;
-(void)handleNotification:(NSDictionary *)payload appState:(UIApplicationState)state;
-(void)showActiveStateNotificationBanner :(FCChannels *)channel withMessage:(NSString *)message;
+(BOOL)areNotificationsEnabled;
+(NSDictionary *)getPayloadFromNotificationInfo:(NSDictionary *)info;

@end
