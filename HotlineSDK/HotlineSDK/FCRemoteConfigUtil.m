//
//  FCRemoteConfig.m
//  HotlineSDK
//
//  Created by user on 24/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCRemoteConfigUtil.h"

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



@end
