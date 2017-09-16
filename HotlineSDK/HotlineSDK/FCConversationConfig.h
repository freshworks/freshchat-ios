//
//  FCMiscFeatures.h
//  HotlineSDK
//
//  Created by user on 06/08/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FCConversationConfig : NSObject

/*
 REAL_AGENT_AVATAR  - 1
 APP_ICON = 2,
 NONE = 3
 */

@property (nonatomic, assign) int agentAvatar;
@property (nonatomic, assign) float activeConvFetchBackoffRatio;
@property (nonatomic, assign) BOOL launchDeeplinkFromNotification;
@property (nonatomic, assign) long activeConvWindow;

- (void) updateConvConfig : (NSDictionary *) configDict;

@end
