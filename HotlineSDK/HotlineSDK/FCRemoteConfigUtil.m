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

- (instancetype)init{
    self = [super init];
    if (self) {
        self.remoteConfig = [[FCRemoteConfig alloc] init];
    }
    return self;
}

-(void)updateFeaturesConfig:(FCEnabledFeatures *)features{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    if (features) {
        [store setBoolValue:features.isFAQEnabled forKey:FRESHCHAT_CONFIG_RC_FAQ_ENABLED];
        [store setBoolValue:features.isInboxEnabled forKey:FRESHCHAT_CONFIG_RC_INBOX_ENABLED];
        [store setBoolValue:features.isAutoCampaignsEnabled forKey:FRESHCHAT_CONFIG_RC_AUTO_CAMPAIGNS_ENABLED];
        [store setBoolValue:features.isManualCampaignsEnabled forKey:FRESHCHAT_CONFIG_RC_MANUAL_CAMPAIGNS_ENABLED];
        [store setBoolValue:features.isUserEventsEnabled forKey:FRESHCHAT_CONFIG_RC_USER_EVENTS_ENABLED];
        [store setBoolValue:features.isAOTUserCreateEnabled forKey:FRESHCHAT_CONFIG_RC_AOT_USER_CREATE_ENABLED];
        [store setBoolValue:features.showCustomBrandBanner forKey:FRESHCHAT_CONFIG_RC_CUSTOM_BRAND_BANNER_ENABLED];
        [store setBoolValue:features.conversationConfig.showAgentAvatars forKey:FRESHCHAT_CONFIG_RC_SHOW_AGENT_AVATAR];
        [store setBoolValue:features.conversationConfig.launchDeeplinkFromNotification forKey:FRESHCHAT_CONFIG_RC_LAUNCH_DEEPLINK_NOTIFICATION];
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

//FC interval call
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

+ (long) setFaqFetchIntervalLaidback {
    return ([HLUserDefaults getLongForKey:CONFIG_RC_FAQ_FETCH_INTERVAL_LAIDBACK]);
}

+ (long) getChannelsFetchIntervalNormal {
    return ([HLUserDefaults getLongForKey:CONFIG_RC_CHANNELS_FETCH_INTERVAL_NORMAL]);
}

+ (long) setChannelsFetchIntervalLaidback {
    return ([HLUserDefaults getLongForKey:CONFIG_RC_CHANNELS_FETCH_INTERVAL_LAIDBACK]);
}

+ (long) getResponseTimeExpectationsFetchInterval {
    return ([HLUserDefaults getLongForKey:CONFIG_RC_RESPONSE_TIME_EXPECTATION_FETCH_INTERVAL]);
}

+ (long) setResponseTimeExpectationsFetchInterval{
    return ([HLUserDefaults getLongForKey:CONFIG_RC_RESPONSE_TIME_EXPECTATION_FETCH_INTERVAL]);
}

+ (int) getActiveConvWindow {
    return ([[HLUserDefaults getNumberForKey:CONFIG_RC_ACTIVE_CONV_WINDOW] intValue]);
}
//FC CONFIG_RC_ACTIVE_CONV_WINDOW

+ (long) getSessionDuration{
    return ([HLUserDefaults getLongForKey:CONFIG_RC_SESSION_DURATION_SECS]);
}

+ (BOOL) isActiveConvAvailable{
    
    long days = [Message daysSinceLastMessageInContext: [[KonotorDataManager sharedInstance] mainObjectContext]];
    if( days * ONE_SECONDS_IN_MS < [FCRemoteConfigUtil getActiveConvWindow]){
        return true;
    }
    return false;
}

@end
