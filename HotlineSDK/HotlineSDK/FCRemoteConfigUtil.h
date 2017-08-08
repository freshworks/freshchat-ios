//
//  FCRemoteConfigUtil.h
//  HotlineSDK
//
//  Created by user on 25/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "HLUserDefaults.h"
#import "FCRemoteConfig.h"

@interface FCRemoteConfigUtil : NSObject

@property(nonatomic, strong) FCRemoteConfig *remoteConfig;

-(void)updateFeaturesConfig:(FCFeatures *)features;
+ (BOOL) isAccountActive;
+ (BOOL) isFAQEnabled;
+ (BOOL) isInboxEnabled;
+ (BOOL) isActiveInboxAndAccount;
+ (BOOL) isActiveFAQAndAccount;
+ (BOOL) isSubscribedUser;

+ (float) getActiveConvFetchBackoffRatio;

//Config intervals -
+ (long) getRemoteConfigFetchInterval;

+ (long) getActiveConvMaxFetchInterval;
+ (long) getActiveConvMinFetchInterval;

+ (long) getMsgFetchIntervalNormal;
+ (long) getMsgFetchIntervalLaidback;

+ (long) getFaqFetchIntervalNormal;
+ (long) setFaqFetchIntervalLaidback;

+ (long) getChannelsFetchIntervalNormal;
+ (long) setChannelsFetchIntervalLaidback;
+ (int) getActiveConvWindow;

+ (long) getSessionDuration;

+ (BOOL) isActiveConvAvailable;

@end
