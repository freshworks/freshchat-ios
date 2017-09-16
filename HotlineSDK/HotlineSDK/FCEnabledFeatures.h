//
//  FCFeatures.h
//  HotlineSDK
//
//  Created by user on 27/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

//FAQ, INBOX, AUTO_CAMPAIGNS, MANUAL_CAMPAIGNS, USER_EVENTS, AOT_USER_CREATE, CUSTOM_BRAND_BANNER

enum FCEnabledFeatureType {
    faq = 0,
    inbox,
    autoCampaigns,
    manualCampaigns,
    userEvents,
    aotUserCreate,
    showCustomBrandBanner
};

@interface FCEnabledFeatures : NSObject

+ (instancetype) sharedInstance ;

@property (nonatomic, assign) BOOL faqEnabled;
@property (nonatomic, assign) BOOL inboxEnabled;
@property (nonatomic, assign) BOOL autoCampaignsEnabled;
@property (nonatomic, assign) BOOL manualCampaignsEnabled;
@property (nonatomic, assign) BOOL userEventsEnabled;
@property (nonatomic, assign) BOOL aotUserCreateEnabled;
@property (nonatomic, assign) BOOL showCustomBrandBanner;

- (void) updateConvConfig : (NSArray *) configDict;

@end
