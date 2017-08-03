//
//  FCRemoteConfig.m
//  HotlineSDK
//
//  Created by user on 24/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCRemoteConfigUtil.h"
#import "FDSecureStore.h"

@implementation FCRemoteConfigUtil

- (instancetype)init{
    self = [super init];
    if (self) {
        self.remoteConfig = [[FCRemoteConfig alloc] init];
        [HLUserDefaults setNumber : @(self.remoteConfig.sessionDuration) forKey: CONFIG_RC_SESSION_DURATION_SECS];
        [HLUserDefaults setNumber : @(self.remoteConfig.activeConvWindow) forKey: CONFIG_RC_ACTIVE_CONV_WINDOW];
        [HLUserDefaults setString : [@(self.remoteConfig.activeConvFetchBackoffRatio) stringValue] forKey: CONFIG_RC_ACTIVE_CONV_FETCH_BACKOFF_RATIO];
        
        FCRefreshIntervals *intervals = self.remoteConfig.refreshIntervals;
        if(intervals){
            
            [HLUserDefaults setNumber:@(intervals.activeConvMinFetchInterval) forKey:CONFIG_RC_ACTIVE_CONV_MIN_FETCH_INTERVAL];
            [HLUserDefaults setNumber:@(intervals.activeConvMaxFetchInterval) forKey:CONFIG_RC_ACTIVE_CONV_MAX_FETCH_INTERVAL];
            [HLUserDefaults setNumber:@(intervals.channelsFetchIntervalLaidback) forKey:CONFIG_RC_CHANNELS_FETCH_INTERVAL_LAIDBACK];
            [HLUserDefaults setNumber:@(intervals.channelsFetchIntervalNormal) forKey:CONFIG_RC_CHANNELS_FETCH_INTERVAL_NORMAL];
            [HLUserDefaults setNumber:@(intervals.faqFetchIntervalLaidback) forKey:CONFIG_RC_FAQ_FETCH_INTERVAL_LAIDBACK];
            [HLUserDefaults setNumber:@(intervals.faqFetchIntervalNormal) forKey:CONFIG_RC_FAQ_FETCH_INTERVAL_NORMAL];
            [HLUserDefaults setNumber:@(intervals.msgFetchIntervalLaidback) forKey:CONFIG_RC_MSG_FETCH_INTERVAL_LAIDBACK];
            [HLUserDefaults setNumber:@(intervals.msgFetchIntervalNormal) forKey:CONFIG_RC_MSG_FETCH_INTERVAL_NORMAL];
        }
    }
    return self;
}

-(void)updateFeaturesConfig:(FCFeatures *)features{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    if (features) {
        [store setBoolValue:features.isFAQEnabled forKey:FRESHCHAT_CONFIG_RC_FAQ_ENABLED];
        [store setBoolValue:features.isInboxEnabled forKey:FRESHCHAT_CONFIG_RC_INBOX_ENABLED];
        [store setBoolValue:features.isAutoCampaignsEnabled forKey:FRESHCHAT_CONFIG_RC_AUTO_CAMPAIGNS_ENABLED];
        [store setBoolValue:features.isManualCampaignsEnabled forKey:FRESHCHAT_CONFIG_RC_MANUAL_CAMPAIGNS_ENABLED];
        [store setBoolValue:features.isUserEventsEnabled forKey:FRESHCHAT_CONFIG_RC_USER_EVENTS_ENABLED];
        [store setBoolValue:features.isAOTUserCreateEnabled forKey:FRESHCHAT_CONFIG_RC_AOT_USER_CREATE_ENABLED];
        [store setBoolValue:features.showCustomBrandBanner forKey:FRESHCHAT_CONFIG_RC_CUSTOM_BRAND_BANNER_ENABLED];
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
    return ([[HLUserDefaults getNumberForKey:CONFIG_RC_ACTIVE_CONV_FETCH_BACKOFF_RATIO] floatValue]);
}

//FC interval call
+ (long) getRemoteConfigFetchInterval{
    return ([[HLUserDefaults getNumberForKey:CONFIG_RC_API_FETCH_INTERVAL] longValue]);
}

+ (long) getActiveConvMaxFetchInterval {
    return ([[HLUserDefaults getNumberForKey:CONFIG_RC_ACTIVE_CONV_MAX_FETCH_INTERVAL] longValue]);
}

+ (long) getActiveConvMinFetchInterval {
    return ([[HLUserDefaults getNumberForKey:CONFIG_RC_ACTIVE_CONV_MIN_FETCH_INTERVAL] longValue]);
}

+ (long) getMsgFetchIntervalNormal {
    return ([[HLUserDefaults getNumberForKey:CONFIG_RC_MSG_FETCH_INTERVAL_NORMAL] longValue]);
}

+ (long) getMsgFetchIntervalLaidback {
    return ([[HLUserDefaults getNumberForKey:CONFIG_RC_MSG_FETCH_INTERVAL_LAIDBACK] longValue]);
}

+ (long) getFaqFetchIntervalNormal {
    return ([[HLUserDefaults getNumberForKey:CONFIG_RC_FAQ_FETCH_INTERVAL_NORMAL] longValue]);
}

+ (long) setFaqFetchIntervalLaidback {
    return ([[HLUserDefaults getNumberForKey:CONFIG_RC_FAQ_FETCH_INTERVAL_LAIDBACK] longValue]);
}

+ (long) getChannelsFetchIntervalNormal {
    return ([[HLUserDefaults getNumberForKey:CONFIG_RC_CHANNELS_FETCH_INTERVAL_NORMAL] longValue]);
}

+ (long) setChannelsFetchIntervalLaidback {
    return ([[HLUserDefaults getNumberForKey:CONFIG_RC_CHANNELS_FETCH_INTERVAL_LAIDBACK] longValue]);
}

+ (int) getActiveConvWindow {
    return ([[HLUserDefaults getNumberForKey:CONFIG_RC_ACTIVE_CONV_WINDOW] intValue]);
}
//FC CONFIG_RC_ACTIVE_CONV_WINDOW

+ (long) getSessionDuration{
    return ([[HLUserDefaults getNumberForKey:CONFIG_RC_SESSION_DURATION_SECS] longValue]);
}

@end
