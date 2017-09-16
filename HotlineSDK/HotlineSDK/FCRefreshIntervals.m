//
//  FCRefreshIntervals.m
//  HotlineSDK
//
//  Created by user on 24/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCRefreshIntervals.h"

@implementation FCRefreshIntervals

+ (instancetype)sharedInstance {
    static FCRefreshIntervals *sharedFCRefreshIntervals = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedFCRefreshIntervals = [[self alloc]init];
    });
    return sharedFCRefreshIntervals;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.responseTimeExpectationsFetchInterval = [self getDefaultValue:responseTimeExpectationsFetchInterval];
        self.remoteConfigFetchInterval = [self getDefaultValue:remoteConfigFetchInterval];
        self.activeConvMinFetchInterval = [self getDefaultValue:activeConvMinFetchInterval];
        self.activeConvMaxFetchInterval = [self getDefaultValue:activeConvMaxFetchInterval];
        self.msgFetchIntervalNormal = [self getDefaultValue:msgFetchIntervalNormal];
        self.msgFetchIntervalLaidback = [self getDefaultValue:msgFetchIntervalLaidback];
        self.faqFetchIntervalNormal = [self getDefaultValue:faqFetchIntervalNormal];
        self.faqFetchIntervalLaidback = [self getDefaultValue:faqFetchIntervalLaidback];
        self.channelsFetchIntervalNormal = [self getDefaultValue:channelsFetchIntervalNormal];
        self.channelsFetchIntervalLaidback = [self getDefaultValue:channelsFetchIntervalLaidback];
    }
    return self;
}


-(long) getDefaultValue:(enum FCRefreshIntervalType) type {
    switch (type) {
        case responseTimeExpectationsFetchInterval:
            if ([HLUserDefaults getObjectForKey:CONFIG_RC_RESPONSE_TIME_EXPECTATION_FETCH_INTERVAL] != nil ) {
                return (long) [HLUserDefaults getObjectForKey:CONFIG_RC_RESPONSE_TIME_EXPECTATION_FETCH_INTERVAL];
            }
            return 5 * ONE_MINUTE_IN_MS;
            break;
        case remoteConfigFetchInterval:
            if([HLUserDefaults getObjectForKey:CONFIG_RC_API_FETCH_INTERVAL] != nil) {
                return (long)[HLUserDefaults getObjectForKey:CONFIG_RC_API_FETCH_INTERVAL];
            }
            return ONE_HOUR_IN_MS;
            break;
        case activeConvMinFetchInterval:
            if([HLUserDefaults getObjectForKey:CONFIG_RC_ACTIVE_CONV_MIN_FETCH_INTERVAL] != nil) {
                return (long)[HLUserDefaults getObjectForKey:CONFIG_RC_ACTIVE_CONV_MIN_FETCH_INTERVAL];
            }
            return 20 * ONE_SECONDS_IN_MS;
            break;
        case activeConvMaxFetchInterval:
            if([HLUserDefaults getObjectForKey:CONFIG_RC_ACTIVE_CONV_MAX_FETCH_INTERVAL] != nil) {
                return (long)[HLUserDefaults getObjectForKey:CONFIG_RC_ACTIVE_CONV_MAX_FETCH_INTERVAL];
            }
            return 60 * ONE_SECONDS_IN_MS;
            break;
        case msgFetchIntervalNormal:
            if([HLUserDefaults getObjectForKey:CONFIG_RC_MSG_FETCH_INTERVAL_NORMAL] != nil) {
                return (long)[HLUserDefaults getObjectForKey:CONFIG_RC_MSG_FETCH_INTERVAL_NORMAL];
            }
            return 30 * ONE_SECONDS_IN_MS;
            break;
        case msgFetchIntervalLaidback:
            if([HLUserDefaults getObjectForKey:CONFIG_RC_MSG_FETCH_INTERVAL_LAIDBACK] != nil) {
                return (long)[HLUserDefaults getObjectForKey:CONFIG_RC_MSG_FETCH_INTERVAL_LAIDBACK];
            }
            return 60 * ONE_SECONDS_IN_MS;
            break;
        case faqFetchIntervalNormal:
            if([HLUserDefaults getObjectForKey:CONFIG_RC_FAQ_FETCH_INTERVAL_NORMAL] != nil) {
                return (long)[HLUserDefaults getObjectForKey:CONFIG_RC_FAQ_FETCH_INTERVAL_NORMAL];
            }
            return 5 * ONE_MINUTE_IN_MS;
            break;
        case faqFetchIntervalLaidback:
            if([HLUserDefaults getObjectForKey:CONFIG_RC_FAQ_FETCH_INTERVAL_LAIDBACK] != nil) {
                return (long)[HLUserDefaults getObjectForKey:CONFIG_RC_FAQ_FETCH_INTERVAL_LAIDBACK];
            }
            return 2 * ONE_DAY_IN_MS;
            break;
        case channelsFetchIntervalNormal:
            if([HLUserDefaults getObjectForKey:CONFIG_RC_CHANNELS_FETCH_INTERVAL_NORMAL] != nil) {
                return (long)[HLUserDefaults getObjectForKey:CONFIG_RC_CHANNELS_FETCH_INTERVAL_NORMAL];
            }
            return 5 * ONE_MINUTE_IN_MS;
            break;
        case channelsFetchIntervalLaidback:
            if([HLUserDefaults getObjectForKey:CONFIG_RC_CHANNELS_FETCH_INTERVAL_LAIDBACK] != nil) {
                return (long)[HLUserDefaults getObjectForKey:CONFIG_RC_CHANNELS_FETCH_INTERVAL_LAIDBACK];
            }
            return 2 * ONE_DAY_IN_MS;
            break;
    }
}


-(void) setValue:(long)value type:(enum FCRefreshIntervalType) type {
    switch (type) {
        case responseTimeExpectationsFetchInterval:
            [HLUserDefaults setLong:value forKey:CONFIG_RC_RESPONSE_TIME_EXPECTATION_FETCH_INTERVAL];
            self.responseTimeExpectationsFetchInterval = value;
            break;
        case remoteConfigFetchInterval:
            [HLUserDefaults setLong:value forKey:CONFIG_RC_API_FETCH_INTERVAL];
            self.remoteConfigFetchInterval = value;
            break;
        case activeConvMinFetchInterval:
            [HLUserDefaults setLong:value forKey:CONFIG_RC_ACTIVE_CONV_MIN_FETCH_INTERVAL];
            self.activeConvMinFetchInterval = value;
            break;
        case activeConvMaxFetchInterval:
            [HLUserDefaults setLong:value forKey:CONFIG_RC_ACTIVE_CONV_MAX_FETCH_INTERVAL];
            self.activeConvMaxFetchInterval = value;
            break;
        case msgFetchIntervalNormal:
            [HLUserDefaults setLong:value forKey:CONFIG_RC_MSG_FETCH_INTERVAL_NORMAL];
            self.msgFetchIntervalNormal = value;
            break;
        case msgFetchIntervalLaidback:
            [HLUserDefaults setLong:value forKey:CONFIG_RC_MSG_FETCH_INTERVAL_LAIDBACK];
            self.msgFetchIntervalLaidback = value;
            break;
        case faqFetchIntervalNormal:
            [HLUserDefaults setLong:value forKey:CONFIG_RC_FAQ_FETCH_INTERVAL_NORMAL];
            self.faqFetchIntervalNormal = value;
            break;
        case faqFetchIntervalLaidback:
            [HLUserDefaults setLong:value forKey:CONFIG_RC_FAQ_FETCH_INTERVAL_LAIDBACK];
            self.faqFetchIntervalLaidback = value;
            break;
        case channelsFetchIntervalNormal:
            [HLUserDefaults setLong:value forKey:CONFIG_RC_CHANNELS_FETCH_INTERVAL_NORMAL];
            self.channelsFetchIntervalNormal = value;
            break;
        case channelsFetchIntervalLaidback:
            [HLUserDefaults setLong:value forKey:CONFIG_RC_CHANNELS_FETCH_INTERVAL_LAIDBACK];
            self.channelsFetchIntervalLaidback = value;
            break;
    }
}

- (void) updateRefreshConfig : (NSDictionary *) configDict {
    [self setValue:[[configDict objectForKey:@"activeConvMaxFetchInterval"] longValue] type:activeConvMaxFetchInterval];
    [self setValue:[[configDict objectForKey:@"activeConvMinFetchInterval"] longValue] type:activeConvMinFetchInterval];
    [self setValue:[[configDict objectForKey:@"channelsFetchIntervalNormal"] longValue] type:channelsFetchIntervalNormal];
    [self setValue:[[configDict objectForKey:@"channelsFetchIntervalLaidback"] longValue] type:channelsFetchIntervalLaidback];
    [self setValue:[[configDict objectForKey:@"faqFetchIntervalNormal"] longValue] type:faqFetchIntervalNormal];
    [self setValue:[[configDict objectForKey:@"faqFetchIntervalLaidback"] longValue] type:faqFetchIntervalLaidback];
    [self setValue:[[configDict objectForKey:@"msgFetchIntervalNormal"] longValue] type:msgFetchIntervalNormal];
    [self setValue:[[configDict objectForKey:@"msgFetchIntervalLaidback"] longValue] type:msgFetchIntervalLaidback];
    [self setValue:[[configDict objectForKey:@"remoteConfigFetchInterval"] longValue] type:remoteConfigFetchInterval];
    [self setValue:[[configDict objectForKey:@"responseTimeExpectationsFetchInterval"] longValue] type:responseTimeExpectationsFetchInterval];
}

@end
