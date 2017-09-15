//
//  FCRefreshIntervals.h
//  HotlineSDK
//
//  Created by user on 24/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLUserDefaults.h"

#define ONE_SECONDS_IN_MS 1000
#define ONE_HOUR_IN_MS (3600 * ONE_SECONDS_IN_MS)
#define ONE_MINUTE_IN_MS (60 * 1000)
#define ONE_DAY_IN_MS (24 * ONE_HOUR_IN_MS)

@interface FCRefreshIntervals : NSObject

@property (nonatomic, assign) long responseTimeExpectationsFetchInterval;

@property (nonatomic, assign) long remoteConfigFetchInterval;

@property (nonatomic, assign) long activeConvMinFetchInterval;
@property (nonatomic, assign) long activeConvMaxFetchInterval;

@property (nonatomic, assign) long msgFetchIntervalNormal;
@property (nonatomic, assign) long msgFetchIntervalLaidback;

@property (nonatomic, assign) long faqFetchIntervalNormal;
@property (nonatomic, assign) long faqFetchIntervalLaidback;

@property (nonatomic, assign) long channelsFetchIntervalNormal;
@property (nonatomic, assign) long channelsFetchIntervalLaidback;

- (instancetype)init;

@end
