//
//  FDDataUpdaterWithInterval.h
//  FreshdeskSDK
//
//  Created by Hrishikesh on 06/11/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FDSecureStore.h"
#import "MobiHelpDatabase.h"
#import "FDAPIClient.h"
#import "FDCoreDataImporter.h"

@interface FDDataUpdaterWithInterval : NSObject

@property (nonatomic        ) int              intervalInSecs;
@property (nonatomic        ) NSString         * intervalConfigKey;
@property (strong, nonatomic) FDSecureStore    *secureStore;
@property (strong, nonatomic) MobiHelpDatabase *database;

- (void) fetchWithCompletion:(void(^)(NSError *error))completion;
- (void) fetch;
- (void) doFetch:(void(^)(NSError *error))completion;
- (void) resetTime;
- (BOOL) hasTimedOut;
- (void) noUpdate;

@end
