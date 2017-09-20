//
//  FCMiscFeatures.m
//  HotlineSDK
//
//  Created by user on 06/08/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCConversationConfig.h"
#import "HLUserDefaults.h"
#import "FCRefreshIntervals.h"

@implementation FCConversationConfig

-(instancetype)init{
    self = [super init];
    if (self) {
        self.agentAvatar                    = [self getDefaultAgentAvatar];
        self.launchDeeplinkFromNotification = [self getDefaultLaunchDeeplinkFromNotification];
        self.activeConvFetchBackoffRatio    = [self getDefaultActiveConvFetchBackoffRatio];
        self.activeConvWindow               = [self getDefaultActiveConvWindow];
    }
    return self;
}

- (BOOL) getDefaultLaunchDeeplinkFromNotification {
    if ([HLUserDefaults getObjectForKey:CONFIG_RC_NOTIFICATION_DEEPLINK_ENABLED] != nil) {
        return [HLUserDefaults getBoolForKey:CONFIG_RC_NOTIFICATION_DEEPLINK_ENABLED];
    }
    return YES;
}

- (int) getDefaultAgentAvatar {
    if ([HLUserDefaults getObjectForKey:CONFIG_RC_AGENT_AVATAR_TYPE] != nil) {
        return (int)[HLUserDefaults getIntegerForKey:CONFIG_RC_AGENT_AVATAR_TYPE];
    }
    return 1;
}

- (float) getDefaultActiveConvFetchBackoffRatio {
    if ([HLUserDefaults getObjectForKey:CONFIG_RC_ACTIVE_CONV_FETCH_BACKOFF_RATIO] != nil) {
        return [HLUserDefaults getFloatForKey:CONFIG_RC_ACTIVE_CONV_FETCH_BACKOFF_RATIO];
    }
    return 1.25;
}

- (long) getDefaultActiveConvWindow {
    if ([HLUserDefaults getObjectForKey:CONFIG_RC_ACTIVE_CONV_WINDOW] != nil) {
        return [HLUserDefaults getLongForKey:CONFIG_RC_ACTIVE_CONV_WINDOW];
    }
    return 3 * ONE_DAY_IN_MS;
}

- (void) updateLaunchDeeplinkFromNotification :(BOOL) launchDeeplinkFromNotification {
    [HLUserDefaults setBool:launchDeeplinkFromNotification forKey:CONFIG_RC_NOTIFICATION_DEEPLINK_ENABLED];
    self.launchDeeplinkFromNotification = launchDeeplinkFromNotification;
}

- (void) updateAgentAvatar: (int) agentAvatar {
    [HLUserDefaults setIntegerValue:agentAvatar forKey:CONFIG_RC_AGENT_AVATAR_TYPE];
    self.agentAvatar = agentAvatar;
}

- (void) updateActiveConvWindow:(long) activeConvWindow {
    [HLUserDefaults setLong:activeConvWindow forKey:CONFIG_RC_ACTIVE_CONV_WINDOW];
    self.activeConvWindow = activeConvWindow;
}

- (void) updateActiveConvFetchBackOffRatio:(float) activeConvFetchBackoffRatio {
    [HLUserDefaults setFloat:activeConvFetchBackoffRatio forKey:CONFIG_RC_ACTIVE_CONV_FETCH_BACKOFF_RATIO];
    self.activeConvFetchBackoffRatio = activeConvFetchBackoffRatio;
}

- (void) updateConvConfig : (NSDictionary *) configDict {
    NSString* avatarType =  [configDict objectForKey:@"agentAvatars"];
    if (avatarType != nil) {
        if([avatarType isEqualToString:@"REAL_AGENT_AVATAR"]){
            [self updateAgentAvatar:1];
        }
        else if([avatarType isEqualToString:@"APP_ICON"]){
            [self updateAgentAvatar:2];
        }
        else {
            [self updateAgentAvatar:3];
        }
    }
    if([configDict objectForKey:@"activeConvWindow"] != nil) {
        [self updateActiveConvWindow:[[configDict objectForKey:@"activeConvWindow"] longValue]];
    }
    if([configDict objectForKey:@"activeConvFetchBackoffRatio"] != nil) {
        [self updateActiveConvFetchBackOffRatio:[[configDict objectForKey:@"activeConvFetchBackoffRatio"] floatValue]];
    }
    if([configDict objectForKey:@"launchDeeplinkFromNotification"] != nil) {
        [self updateLaunchDeeplinkFromNotification:[[configDict objectForKey:@"launchDeeplinkFromNotification"] boolValue]];
    }
    
}

@end
