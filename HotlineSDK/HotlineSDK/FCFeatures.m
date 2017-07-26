//
//  FCFeatures.m
//  HotlineSDK
//
//  Created by user on 27/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCFeatures.h"

@implementation FCFeatures

-(instancetype)init{
    self = [super init];
    if (self) {
        self.isFAQEnabled = YES;
        self.isInboxEnabled = YES;
        self.isAutoCampaignsEnabled = NO;
        self.isManualCampaignsEnabled = NO;
        self.isUserEventsEnabled = NO;
        self.isAOTUserCreateEnabled = NO;
        self.showCustomBrandBanner = YES;
    }
    return self;
}

@end
