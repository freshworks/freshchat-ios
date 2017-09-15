//
//  FCRefreshIntervals.m
//  HotlineSDK
//
//  Created by user on 24/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCRefreshIntervals.h"



@implementation FCRefreshIntervals

- (instancetype)init{
    self = [super init];
    if (self) {
        self.responseTimeExpectationsFetchInterval = 5 * ONE_MINUTE_IN_MS;
        
        self.remoteConfigFetchInterval = ONE_HOUR_IN_MS;
        
        self.activeConvMinFetchInterval = 20 * ONE_SECONDS_IN_MS;
        self.activeConvMaxFetchInterval = 60 * ONE_SECONDS_IN_MS;
        
        self.msgFetchIntervalNormal = 30 * ONE_SECONDS_IN_MS;
        self.msgFetchIntervalLaidback = 60 * ONE_SECONDS_IN_MS;
        
        self.faqFetchIntervalNormal = 5 * ONE_MINUTE_IN_MS;
        self.faqFetchIntervalLaidback = 2 * ONE_DAY_IN_MS;
        
        self.channelsFetchIntervalNormal = 5 * ONE_MINUTE_IN_MS;
        self.channelsFetchIntervalLaidback = 2 * ONE_DAY_IN_MS;
        
    }
    return self;
}

- (long) getRemoteConfigFetchInterval{
    
    return self.remoteConfigFetchInterval;
}

- (void) setRemoteConfigFetchInterval:(long)remoteConfigFetchInterval{
    
    _remoteConfigFetchInterval = remoteConfigFetchInterval;
    [HLUserDefaults setLong:remoteConfigFetchInterval forKey:CONFIG_RC_API_FETCH_INTERVAL];
}

- (long) getActiveConvMaxFetchInterval{
    
    return self.activeConvMaxFetchInterval;
}

- (void) setActiveConvMaxFetchInterval:(long)activeConvMaxFetchInterval{
    
    _activeConvMaxFetchInterval = activeConvMaxFetchInterval;
    [HLUserDefaults setLong:activeConvMaxFetchInterval forKey:CONFIG_RC_ACTIVE_CONV_MAX_FETCH_INTERVAL];
}

- (long) getActiveConvMinFetchInterval:(long)activeConvMinFetchInterval{
    
    return  self.activeConvMinFetchInterval = activeConvMinFetchInterval;
}

- (void) setActiveConvMinFetchInterval:(long)activeConvMinFetchInterval{
    
    _activeConvMinFetchInterval = activeConvMinFetchInterval;
    [HLUserDefaults setLong:activeConvMinFetchInterval forKey:CONFIG_RC_ACTIVE_CONV_MIN_FETCH_INTERVAL];
}

- (long) getMsgFetchIntervalNormal:(long)msgFetchIntervalNormal{
    
    return self.msgFetchIntervalNormal;
}

- (void) setMsgFetchIntervalNormal:(long)msgFetchIntervalNormal{
    
    _msgFetchIntervalNormal = msgFetchIntervalNormal;
    [HLUserDefaults setLong:msgFetchIntervalNormal forKey:CONFIG_RC_MSG_FETCH_INTERVAL_NORMAL];
}

- (long) getMsgFetchIntervalLaidback:(long)msgFetchIntervalLaidback{
    
    return self.msgFetchIntervalLaidback;
}

- (void) setMsgFetchIntervalLaidback:(long)msgFetchIntervalLaidback{
    
    _msgFetchIntervalLaidback = msgFetchIntervalLaidback;
    [HLUserDefaults setLong:msgFetchIntervalLaidback forKey:CONFIG_RC_MSG_FETCH_INTERVAL_LAIDBACK];
}

- (long) getFaqFetchIntervalNormal:(long)faqFetchIntervalNormal{
    
    return self.faqFetchIntervalNormal;
}

- (void) setFaqFetchIntervalNormal:(long)faqFetchIntervalNormal{
    
    _faqFetchIntervalNormal = faqFetchIntervalNormal;
    [HLUserDefaults setLong:faqFetchIntervalNormal forKey:CONFIG_RC_FAQ_FETCH_INTERVAL_NORMAL];
}

- (long) getFaqFetchIntervalLaidback:(long)faqFetchIntervalLaidback{
    
    return self.faqFetchIntervalLaidback;
}

- (void) setFaqFetchIntervalLaidback:(long)faqFetchIntervalLaidback{
    
    _faqFetchIntervalLaidback = faqFetchIntervalLaidback;
    [HLUserDefaults setLong:faqFetchIntervalLaidback forKey:CONFIG_RC_FAQ_FETCH_INTERVAL_LAIDBACK];
}

- (long) getChannelsFetchIntervalNormal:(long)channelsFetchIntervalNormal{
    
    return self.channelsFetchIntervalNormal;
}

- (void) setChannelsFetchIntervalNormal:(long)channelsFetchIntervalNormal{
    
    _channelsFetchIntervalNormal = channelsFetchIntervalNormal;
    [HLUserDefaults setLong:channelsFetchIntervalNormal forKey:CONFIG_RC_CHANNELS_FETCH_INTERVAL_NORMAL];
}

- (long) getChannelsFetchIntervalLaidback:(long)channelsFetchIntervalLaidback {
    
    return self.channelsFetchIntervalLaidback;
}

- (void) setChannelsFetchIntervalLaidback:(long)channelsFetchIntervalLaidback {
    
    _channelsFetchIntervalLaidback = channelsFetchIntervalLaidback;
    [HLUserDefaults setObject:[NSNumber numberWithLong:channelsFetchIntervalLaidback] forKey:CONFIG_RC_CHANNELS_FETCH_INTERVAL_LAIDBACK];
}

- (long) getResponseTimeExpectationsFetchInterval : (long) responseTimeExpectationsFetchInterval{
    return self.responseTimeExpectationsFetchInterval;
}

- (void) setResponseTimeExpectationsFetchInterval:(long)responseTimeExpectationsFetchInterval{
    _responseTimeExpectationsFetchInterval = responseTimeExpectationsFetchInterval;
    [HLUserDefaults setObject:[NSNumber numberWithLong:responseTimeExpectationsFetchInterval] forKey:CONFIG_RC_RESPONSE_TIME_EXPECTATION_FETCH_INTERVAL];
    
}

@end
