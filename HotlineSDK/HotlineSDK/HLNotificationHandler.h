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

#define HOTLINE_NOTIFICATION_PAYLOAD_CHANNEL_ID @"kon_c_ch_id"
#define HOTLINE_NOTIFICATION_PAYLOAD_MARKETING_ID @"kon_message_marketingid"

@interface HLNotificationHandler : NSObject<FDNotificationBannerDelegate>

+(BOOL)isHotlineNotification:(NSDictionary *)info;
-(void)handleNotification:(NSDictionary *)payload appState:(UIApplicationState)state;
-(void)showActiveStateNotificationBanner :(HLChannel *)channel withMessage:(NSString *)message;
+(BOOL)areNotificationsEnabled;
+(NSDictionary *)getPayloadFromNotificationInfo:(NSDictionary *)info;

@end
