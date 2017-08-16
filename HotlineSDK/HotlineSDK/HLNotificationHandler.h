//
//  HLNotificationHandler.h
//  HotlineSDK
//
//  Created by Harish Kumar on 05/04/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FDNotificationBanner.h"

#define FRESHCHAT_NOTIFICATION_PAYLOAD_CHANNEL_ID @"channel_id"
#define FRESHCHAT_NOTIFICATION_PAYLOAD_CONV_ID @"conv_id"
#define FRESHCHAT_NOTIFICATION_PAYLOAD_MARKETING_ID @"marketing_id"
#define FRESHCHAT_NOTIFICATION_PAYLOAD_SOURCE_USER @"freshchat_user"
#define FRESHCHAT_NOTIFICATION_PAYLOAD _TARGET_USER_ALIAS @"target_user_alias"

@interface HLNotificationHandler : NSObject<FDNotificationBannerDelegate>

+(BOOL)isHotlineNotification:(NSDictionary *)info;
-(void)handleNotification:(NSDictionary *)payload appState:(UIApplicationState)state;
-(void)showActiveStateNotificationBanner :(HLChannel *)channel withMessage:(NSString *)message;
+(BOOL)areNotificationsEnabled;
+(NSDictionary *)getPayloadFromNotificationInfo:(NSDictionary *)info;

@end
