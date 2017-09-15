//
//  FCMiscFeatures.h
//  HotlineSDK
//
//  Created by user on 06/08/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

enum AgentAvatarType {
    REAL_AGENT_AVATAR = 1,
    APP_ICON = 2,
    NONE = 2
};

@interface FCConversationConfig : NSObject

@property (nonatomic, assign) enum AgentAvatarType showAgentAvatars;
@property (nonatomic, assign) float activeConvFetchBackoffRatio;
@property (nonatomic, assign) BOOL launchDeeplinkFromNotification;
@property (nonatomic, assign) long activeConvWindow;

-(id) init;

@end
