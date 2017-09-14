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

@interface FCRemoteConfig : NSObject

@property (nonatomic, assign) BOOL accountActive;
@property (nonatomic, assign) long sessionDuration;
@property (nonatomic, assign) long activeConvWindow;

@property (nonatomic, strong) FCRefreshIntervals *refreshIntervals;
@property (nonatomic, strong) FCEnabledFeatures *features;

@end
