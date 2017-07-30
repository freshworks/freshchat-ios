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
        self.accountActive = true;
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

- (void) setAccountActive:(BOOL)accountActive{
    
    [HLUserDefaults setBool:accountActive forKey:CONFIG_RC_IS_ACCOUNT_ACTIVE];
}

- (long) getSessionDuration{
    
    return self.sessionDuration;
}

- (void) setSessionDuration:(long)sessionDuration{
    [HLUserDefaults setObject:[NSNumber numberWithLong:sessionDuration] forKey:CONFIG_RC_SESSION_DURATION_SECS];
}

- (long) getActiveConvWindow{
    
    return self.activeConvWindow;
}

- (void) setActiveConvWindow:(long)activeConvWindow{
    
    [HLUserDefaults setObject:[NSNumber numberWithLong:activeConvWindow] forKey:CONFIG_RC_ACTIVE_CONV_WINDOW];
}

- (double) getActiveConvFetchBackoffRatio{
    
    return self.activeConvFetchBackoffRatio;
}

- (void) setActiveConvFetchBackoffRatio:(double)activeConvFetchBackoffRatio{
    
    [HLUserDefaults setObject:[NSNumber numberWithDouble:activeConvFetchBackoffRatio] forKey:CONFIG_RC_ACTIVE_CONV_FETCH_BACKOFF_RATIO];
}

- (FCRefreshIntervals *) getRefreshIntervals{
    
    return self.refreshIntervals;
}


@end
