//
//  FCFeatures.h
//  HotlineSDK
//
//  Created by user on 27/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FCFeatures : NSObject

//FAQ, INBOX, AUTO_CAMPAIGNS, MANUAL_CAMPAIGNS, USER_EVENTS, AOT_USER_CREATE, CUSTOM_BRAND_BANNER
@property (nonatomic, assign) BOOL isFAQEnabled;
@property (nonatomic, assign) BOOL isInboxEnabled;
@property (nonatomic, assign) BOOL isAutoCampaignsEnabled;
@property (nonatomic, assign) BOOL isManualCampaignsEnabled;
@property (nonatomic, assign) BOOL isUserEventsEnabled;
@property (nonatomic, assign) BOOL isAOTUserCreateEnabled;
@property (nonatomic, assign) BOOL showCustomBrandBanner;

@end
