//
//  FDDataUpdaterWithInterval.h
//  FreshdeskSDK
//
//  Created by Hrishikesh on 06/11/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCSecureStore.h"
#import "FCDataManager.h"
#import "FCAPIClient.h"

@interface FCDataUpdaterWithInterval : NSObject

- (void) fetchWithCompletion:(void(^)(BOOL isFetchPerformed, NSError *error))completion;
- (void) fetch;
- (void) doFetch:(void(^)(NSError *error))completion;
- (void) resetTime;
- (void) resetTimeTo:(NSNumber *) value;
- (BOOL) hasTimedOut;
- (void) noUpdate;
- (void) useInterval:(long) interval;
- (void) useConfigKey:(NSString *) configKey;

@end
