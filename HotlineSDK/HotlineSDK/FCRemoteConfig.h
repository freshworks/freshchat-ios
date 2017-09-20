//
//  FCRemoteConfig.h
//  HotlineSDK
//
//  Created by user on 25/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCRefreshIntervals.h"
#import "FCEnabledFeatures.h"
#import "FCConversationConfig.h"
#import "HLUserDefaults.h"

@interface FCRemoteConfig : NSObject

+(instancetype)sharedInstance;

@property (nonatomic, assign) BOOL accountActive;
@property (nonatomic, assign) long sessionTimeOutInterval;
@property (nonatomic, assign) float activeConvFetchBackoffRatio;
@property (nonatomic, assign) long activeConvWindow;

@property (nonatomic, strong) FCConversationConfig *conversationConfig;
@property (nonatomic, strong) FCRefreshIntervals *refreshIntervals;
@property (nonatomic, strong) FCEnabledFeatures *enabledFeatures;

- (void) updateRemoteConfig : (NSDictionary *) configDict;

- (BOOL) isActiveInboxAndAccount;
- (BOOL) isActiveFAQAndAccount;
- (BOOL) isActiveConvAvailable;

@end
