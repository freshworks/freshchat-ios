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

@property (nonatomic) long remoteConfigFetchInterval;

@property (nonatomic) long activeConvMinFetchInterval;
@property (nonatomic) long activeConvMaxFetchInterval;

@property (nonatomic) long msgFetchIntervalNormal;
@property (nonatomic) long msgFetchIntervalLaidback;

@property (nonatomic) long faqFetchIntervalNormal;
@property (nonatomic) long faqFetchIntervalLaidback;

@property (nonatomic) long channelsFetchIntervalNormal;
@property (nonatomic) long channelsFetchIntervalLaidback;

- (instancetype)init;
- (void) setFaqFetchIntervalNormal:(long)faqFetchIntervalNormal;

@end
