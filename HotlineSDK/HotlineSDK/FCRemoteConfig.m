//
//  FCRemoteConfig.m
//  HotlineSDK
//
//  Created by user on 25/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCRemoteConfig.h"

@implementation FCRemoteConfig

- (instancetype)init{
    self = [super init];
    if (self) {
        self.accountActive = YES;
        self.sessionDuration = 30 * ONE_MINUTE_IN_MS;
        self.activeConvWindow = 3 * ONE_DAY_IN_MS;
        self.activeConvFetchBackoffRatio = 1.25;
        self.refreshIntervals = [[FCRefreshIntervals alloc] init];
        self.features = [[FCFeatures alloc] init];
    }
    return self;
}

- (BOOL) getAccountActive{
    
    return self.accountActive;
}

- (void) setAccountActive:(BOOL)accountActive {
    [HLUserDefaults setBool:accountActive forKey:CONFIG_RC_IS_ACCOUNT_ACTIVE];
    _accountActive = accountActive;
}

- (long) getSessionDuration{
    
    return self.sessionDuration;
}

- (void) setSessionDuration:(long)sessionDuration{
    _sessionDuration = sessionDuration;
    [HLUserDefaults setLong:sessionDuration forKey:CONFIG_RC_SESSION_DURATION_SECS];
}

- (long) getActiveConvWindow{
    
    return self.activeConvWindow;
}

- (void) setActiveConvWindow:(long)activeConvWindow{
    
    _activeConvWindow = activeConvWindow;
    [HLUserDefaults setLong:activeConvWindow forKey:CONFIG_RC_ACTIVE_CONV_WINDOW];
}

- (double) getActiveConvFetchBackoffRatio{
    
    return self.activeConvFetchBackoffRatio;
}

- (void) setActiveConvFetchBackoffRatio:(float)activeConvFetchBackoffRatio{
    
    [HLUserDefaults setFloat:activeConvFetchBackoffRatio forKey:CONFIG_RC_ACTIVE_CONV_FETCH_BACKOFF_RATIO];
    _activeConvFetchBackoffRatio = activeConvFetchBackoffRatio;
}

- (FCRefreshIntervals *) getRefreshIntervals{
    
    return self.refreshIntervals;
}

- (void) setRefreshIntervals:(FCRefreshIntervals *)refreshIntervals{
    _refreshIntervals = refreshIntervals;
}

- (void) setFeatures:(FCFeatures *)features{
    _features = features;
}

- (FCFeatures *) getFeatures {
    return self.features;
}

@end
