//
//  FCRemoteConfig.h
//  HotlineSDK
//
//  Created by user on 25/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCRefreshIntervals.h"

@interface FCRemoteConfig : NSObject

@property (nonatomic) BOOL accountActive;
@property (nonatomic) long sessionDuration;
@property (nonatomic) long activeConvWindow;
@property (nonatomic) double activeConvFetchBackoffRatio;
@property (nonatomic, strong) FCRefreshIntervals *refreshIntervals;

@end
