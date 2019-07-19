//
//  FCMiscFeatures.m
//  HotlineSDK
//
//  Created by user on 06/08/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCConversationConfig.h"
#import "FCUserDefaults.h"
#import "FCRefreshIntervals.h"

@implementation FCConversationConfig

-(instancetype)init{
    self = [super init];
    if (self) {
        self.agentAvatar                    = [self getDefaultAgentAvatar];
        self.launchDeeplinkFromNotification = [self getDefaultLaunchDeeplinkFromNotification];
        self.activeConvFetchBackoffRatio    = [self getDefaultActiveConvFetchBackoffRatio];
        self.activeConvWindow               = [self getDefaultActiveConvWindow];
        self.hideResolvedConversation       = [self getHideResolvedConversation];
        self.hideResolvedConversationMillis = [self getHideResolvedConversationMillis];
        self.reopenedMsgtypes               = [self getReopenedMsgtypes];
        self.resolvedMsgTypes               = [self getResolvedMsgTypes];
    }
    return self;
}

- (BOOL) getDefaultLaunchDeeplinkFromNotification {
    return [FCUserDefaults getBoolForKey:CONFIG_RC_NOTIFICATION_DEEPLINK_ENABLED];
}

- (int) getDefaultAgentAvatar {
    if ([FCUserDefaults getObjectForKey:CONFIG_RC_AGENT_AVATAR_TYPE] != nil) {
        return (int)[FCUserDefaults getIntegerForKey:CONFIG_RC_AGENT_AVATAR_TYPE];
    }
    return 1;
}

- (float) getDefaultActiveConvFetchBackoffRatio {
    if ([FCUserDefaults getObjectForKey:CONFIG_RC_ACTIVE_CONV_FETCH_BACKOFF_RATIO] != nil) {
        return [FCUserDefaults getFloatForKey:CONFIG_RC_ACTIVE_CONV_FETCH_BACKOFF_RATIO];
    }
    return 1.25;
}

- (long) getDefaultActiveConvWindow {
    if ([FCUserDefaults getObjectForKey:CONFIG_RC_ACTIVE_CONV_WINDOW] != nil) {
        return [FCUserDefaults getLongForKey:CONFIG_RC_ACTIVE_CONV_WINDOW];
    }
    return 3 * ONE_DAY_IN_MS;
}

- (BOOL) getHideResolvedConversation {
    if ([FCUserDefaults getObjectForKey:CONFIG_RC_HIDE_RESOLVED_CONVERSATION] != nil) {
        return [FCUserDefaults getBoolForKey:CONFIG_RC_HIDE_RESOLVED_CONVERSATION];
    }
    return FALSE;
}

- (long) getHideResolvedConversationMillis {
    if ([FCUserDefaults getObjectForKey:CONFIG_RC_HIDE_RESOLVED_CONVERSATION_MILLIS] != nil) {
        return [FCUserDefaults getLongForKey:CONFIG_RC_HIDE_RESOLVED_CONVERSATION_MILLIS];
    }
    return ONE_DAY_IN_MS;
}

- (NSArray *) getReopenedMsgtypes {
    if ([FCUserDefaults getObjectForKey:CONFIG_RC_REOPENED_MESSAGE_TYPES] != nil) {
        return [FCUserDefaults getObjectForKey:CONFIG_RC_REOPENED_MESSAGE_TYPES];
    }
    return @[];
}

- (NSArray *) getResolvedMsgTypes {
    if ([FCUserDefaults getObjectForKey:CONFIG_RC_RESOLVED_MESSAGE_TYPES] != nil) {
        return [FCUserDefaults getObjectForKey:CONFIG_RC_RESOLVED_MESSAGE_TYPES];
    }
    return @[];
}

- (void) updateLaunchDeeplinkFromNotification :(BOOL) launchDeeplinkFromNotification {
    [FCUserDefaults setBool:launchDeeplinkFromNotification forKey:CONFIG_RC_NOTIFICATION_DEEPLINK_ENABLED];
    self.launchDeeplinkFromNotification = launchDeeplinkFromNotification;
}

- (void) updateAgentAvatar: (int) agentAvatar {
    [FCUserDefaults setIntegerValue:agentAvatar forKey:CONFIG_RC_AGENT_AVATAR_TYPE];
    self.agentAvatar = agentAvatar;
}

- (void) updateActiveConvWindow:(long) activeConvWindow {
    [FCUserDefaults setLong:activeConvWindow forKey:CONFIG_RC_ACTIVE_CONV_WINDOW];
    self.activeConvWindow = activeConvWindow;
}

- (void) updateActiveConvFetchBackOffRatio:(float) activeConvFetchBackoffRatio {
    [FCUserDefaults setFloat:activeConvFetchBackoffRatio forKey:CONFIG_RC_ACTIVE_CONV_FETCH_BACKOFF_RATIO];
    self.activeConvFetchBackoffRatio = activeConvFetchBackoffRatio;
}


- (void) updateHideResolvedConversation : (BOOL) canHideResolvedConversation{
    [FCUserDefaults setBool:canHideResolvedConversation forKey:CONFIG_RC_HIDE_RESOLVED_CONVERSATION];
    self.hideResolvedConversation = canHideResolvedConversation;
    
}

- (void) updateHideResolvedConversationMillis : (long)hideResolvedConversationMillis {
    [FCUserDefaults setLong:hideResolvedConversationMillis forKey:CONFIG_RC_HIDE_RESOLVED_CONVERSATION_MILLIS];
    self.hideResolvedConversationMillis = hideResolvedConversationMillis;
}

- (void) updateReopenedMsgtypes : (NSArray *)reopenedMsgtypes{
    [FCUserDefaults setObject:reopenedMsgtypes forKey:CONFIG_RC_REOPENED_MESSAGE_TYPES];
    self.reopenedMsgtypes = reopenedMsgtypes;
}

- (void) updateResolvedMsgTypes : (NSArray *)resolvedMsgTypes{
    [FCUserDefaults setObject:resolvedMsgTypes forKey:CONFIG_RC_RESOLVED_MESSAGE_TYPES];
    self.resolvedMsgTypes = resolvedMsgTypes;
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
    
    if([configDict objectForKey:@"hideResolvedConversations"] != nil) {
        [self updateHideResolvedConversation:[[configDict objectForKey:@"hideResolvedConversations"] boolValue]];
    }
    
    if([configDict objectForKey:@"hideResolvedConversationsMillis"] != nil) {
        [self updateHideResolvedConversationMillis:[[configDict objectForKey:@"hideResolvedConversationsMillis"] longValue]];
    }
    
    if([configDict objectForKey:@"resolvedMsgTypes"] != nil) {
        [self updateResolvedMsgTypes:[configDict objectForKey:@"resolvedMsgTypes"]];
    }
    
    if([configDict objectForKey:@"reopenedMsgTypes"] != nil) {
        [self updateReopenedMsgtypes:[configDict objectForKey:@"reopenedMsgTypes"]];
    }
}

@end
