//
//  FCRemoteConfig.m
//  HotlineSDK
//
//  Created by user on 24/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCRemoteConfigUtil.h"
#import "FDSecureStore.h"
#import "Message.h"

@implementation FCRemoteConfigUtil

+(instancetype)sharedInstance{
    static FCRemoteConfigUtil *sharedFCRemoteConfigUtil = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedFCRemoteConfigUtil = [[self alloc] init];
    });
    return sharedFCRemoteConfigUtil;
}


- (id)init{
    self = [super init];
    if (self) {
        self.remoteConfig = [[FCRemoteConfig alloc] init];
    }
    return self;
}

- (void) updateRemoteConfig : (NSDictionary *) configDict{

    self.remoteConfig.accountActive = [[configDict objectForKey:@"accountActive"] boolValue];
    self.remoteConfig.sessionTimeOutInterval = [[configDict objectForKey:@"sessionTimeoutInterval"] longValue];
    
    NSString* avatarType =  [configDict objectForKey:@"agentAvatars"];
    if([avatarType isEqualToString:@"REAL_AGENT_AVATAR"]){
        self.remoteConfig.conversationConfig.agentAvatar = 1;
    }
    else if([avatarType isEqualToString:@"APP_ICON"]){
        self.remoteConfig.conversationConfig.agentAvatar = 2;
    }
    else{
        self.remoteConfig.conversationConfig.agentAvatar = 3;
    }self.remoteConfig.conversationConfig.agentAvatar = 1;    
    
    self.remoteConfig.conversationConfig.activeConvFetchBackoffRatio = [[configDict objectForKey:@"activeConvFetchBackoffRatio"] floatValue];
    self.remoteConfig.conversationConfig.launchDeeplinkFromNotification = [[configDict objectForKey:@"activeConvWindow"] boolValue];
    self.remoteConfig.conversationConfig.activeConvWindow = [[configDict objectForKey:@"activeConvWindow"] longValue];

    self.remoteConfig.refreshIntervals.activeConvMaxFetchInterval = [[configDict objectForKey:@"activeConvMaxFetchInterval"] longValue];
    self.remoteConfig.refreshIntervals.activeConvMinFetchInterval = [[configDict objectForKey:@"activeConvMinFetchInterval"] longValue];
    self.remoteConfig.refreshIntervals.channelsFetchIntervalNormal = [[configDict objectForKey:@"channelsFetchIntervalNormal"] longValue];
    self.remoteConfig.refreshIntervals.channelsFetchIntervalLaidback = [[configDict objectForKey:@"channelsFetchIntervalLaidback"] longValue];
    self.remoteConfig.refreshIntervals.faqFetchIntervalNormal = [[configDict objectForKey:@"faqFetchIntervalNormal"] longValue];
    self.remoteConfig.refreshIntervals.faqFetchIntervalLaidback = [[configDict objectForKey:@"faqFetchIntervalLaidback"] longValue];
    self.remoteConfig.refreshIntervals.msgFetchIntervalNormal = [[configDict objectForKey:@"msgFetchIntervalNormal"] longValue];
    self.remoteConfig.refreshIntervals.msgFetchIntervalLaidback = [[configDict objectForKey:@"msgFetchIntervalLaidback"] longValue];
    self.remoteConfig.refreshIntervals.remoteConfigFetchInterval = [[configDict objectForKey:@"remoteConfigFetchInterval"] longValue];
    self.remoteConfig.refreshIntervals.responseTimeExpectationsFetchInterval = [[configDict objectForKey:@"responseTimeExpectationsFetchInterval"] longValue];
    
    [self updateFeaturesConfig:[configDict objectForKey:@"enabledFeatures"]];
    
}

-(void)updateFeaturesConfig:(NSArray *)features{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    if (features) {
        
        [store setBoolValue:([features containsObject:@"FAQ"])? true : false forKey:FRESHCHAT_CONFIG_RC_FAQ_ENABLED];
        [store setBoolValue:([features containsObject:@"INBOX"])? true : false forKey:FRESHCHAT_CONFIG_RC_INBOX_ENABLED];
        [store setBoolValue:([features containsObject:@"AUTO_CAMPAIGNS"])? true : false forKey:FRESHCHAT_CONFIG_RC_AUTO_CAMPAIGNS_ENABLED];
        
        //No worry now will push in next release
//        [store setBoolValue:features.isManualCampaignsEnabled forKey:FRESHCHAT_CONFIG_RC_MANUAL_CAMPAIGNS_ENABLED];
//        [store setBoolValue:features.isUserEventsEnabled forKey:FRESHCHAT_CONFIG_RC_USER_EVENTS_ENABLED];
//        [store setBoolValue:features.isAOTUserCreateEnabled forKey:FRESHCHAT_CONFIG_RC_AOT_USER_CREATE_ENABLED];
//        [store setBoolValue:true forKey:FRESHCHAT_CONFIG_RC_CUSTOM_BRAND_BANNER_ENABLED];
    }
}

+ (BOOL) isAccountActive {
    return ([HLUserDefaults getBoolForKey:CONFIG_RC_IS_ACCOUNT_ACTIVE]);
}

+ (BOOL) isFAQEnabled {
    return ([[FDSecureStore sharedInstance] boolValueForKey :FRESHCHAT_CONFIG_RC_FAQ_ENABLED]);
}

+ (BOOL) isInboxEnabled {
    return ([[FDSecureStore sharedInstance] boolValueForKey :FRESHCHAT_CONFIG_RC_INBOX_ENABLED]);
}

+ (BOOL) isActiveInboxAndAccount{
    return ([self isAccountActive] && [self isInboxEnabled]);
}

+ (BOOL) isActiveFAQAndAccount{
    return ([self isAccountActive] && [self isFAQEnabled]);
}

+ (BOOL) isSubscribedUser {
    return ([[FDSecureStore sharedInstance] boolValueForKey:FRESHCHAT_CONFIG_RC_CUSTOM_BRAND_BANNER_ENABLED]);
}

+ (float) getActiveConvFetchBackoffRatio{
    return ([HLUserDefaults getFloatForKey:CONFIG_RC_ACTIVE_CONV_FETCH_BACKOFF_RATIO]);
}

+ (BOOL) isAgentAvatarEnabled{
    return ([HLUserDefaults getBoolForKey:CONFIG_RC_AGENT_AVATAR_ENABLED]);
}

+ (BOOL) isDeeplinkFromNotificationEnabled {
    return ([HLUserDefaults getBoolForKey:CONFIG_RC_NOTIFICATION_DEEPLINK_ENABLED]);
}

+ (long) getRemoteConfigFetchInterval{
    return ([HLUserDefaults getLongForKey:CONFIG_RC_API_FETCH_INTERVAL]);
}

+ (long) getActiveConvMaxFetchInterval {
    return ([HLUserDefaults getLongForKey:CONFIG_RC_ACTIVE_CONV_MAX_FETCH_INTERVAL]);
}

+ (long) getActiveConvMinFetchInterval {
    return ([HLUserDefaults getLongForKey:CONFIG_RC_ACTIVE_CONV_MIN_FETCH_INTERVAL]);
}

+ (long) getMsgFetchIntervalNormal {
    return ([HLUserDefaults getLongForKey:CONFIG_RC_MSG_FETCH_INTERVAL_NORMAL]);
}

+ (long) getMsgFetchIntervalLaidback {
    return ([HLUserDefaults getLongForKey:CONFIG_RC_MSG_FETCH_INTERVAL_LAIDBACK]);
}

+ (long) getFaqFetchIntervalNormal {
    return ([HLUserDefaults getLongForKey:CONFIG_RC_FAQ_FETCH_INTERVAL_NORMAL]);
}

+ (long) getFaqFetchIntervalLaidback {
    return ([HLUserDefaults getLongForKey:CONFIG_RC_FAQ_FETCH_INTERVAL_LAIDBACK]);
}

+ (long) getChannelsFetchIntervalNormal {
    return ([HLUserDefaults getLongForKey:CONFIG_RC_CHANNELS_FETCH_INTERVAL_NORMAL]);
}

+ (long) getChannelsFetchIntervalLaidback {
    return ([HLUserDefaults getLongForKey:CONFIG_RC_CHANNELS_FETCH_INTERVAL_LAIDBACK]);
}

+ (long) getResponseTimeExpectationsFetchInterval {
    return ([HLUserDefaults getLongForKey:CONFIG_RC_RESPONSE_TIME_EXPECTATION_FETCH_INTERVAL]);
}

+ (int) getActiveConvWindow {
    return ([[HLUserDefaults getNumberForKey:CONFIG_RC_ACTIVE_CONV_WINDOW] intValue]);
}

+ (long) getSessionTimeoutInterval{
    return ([HLUserDefaults getLongForKey:CONFIG_RC_SESSION_TIMEOUT_INTERVAL]);
}

+ (BOOL) isActiveConvAvailable{
    
    long days = [Message daysSinceLastMessageInContext: [[KonotorDataManager sharedInstance] mainObjectContext]];
    if( days * ONE_SECONDS_IN_MS < [FCRemoteConfigUtil getActiveConvWindow]){
        return true;
    }
    return false;
}

@end
