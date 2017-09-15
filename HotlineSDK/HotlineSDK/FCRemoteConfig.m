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
        self.sessionTimeOutInterval = 30 * ONE_MINUTE_IN_MS;
        self.conversationConfig = [[FCConversationConfig alloc] init];
        self.refreshIntervals = [[FCRefreshIntervals alloc] init];
        self.features = [[FCEnabledFeatures alloc] init];
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

- (long) getSessionTimeOutInterval{
    
    return self.sessionTimeOutInterval;
}

- (void) setSessionDuration:(long)sessionDuration{
    _sessionTimeOutInterval = sessionDuration;
    [HLUserDefaults setLong:sessionDuration forKey:CONFIG_RC_SESSION_TIMEOUT_INTERVAL];
}

- (FCRefreshIntervals *) getRefreshIntervals{
    
    return self.refreshIntervals;
}

- (void) setRefreshIntervals:(FCRefreshIntervals *)refreshIntervals{
    _refreshIntervals = refreshIntervals;
}

- (void) setFeatures:(FCEnabledFeatures *)enabledFeatures{
    _enabledFeatures = enabledFeatures;
}

- (FCEnabledFeatures *) getEnabledFeatures {
    return self.enabledFeatures;
}

@end
