//
//  FCFeatures.m
//  HotlineSDK
//
//  Created by user on 27/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCEnabledFeatures.h"

@implementation FCEnabledFeatures

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
        self.conversationConfig = [[FCConversationConfig alloc] init];
    }
    return self;
}

- (void) setIsFAQEnabled:(BOOL)isFAQEnabled{
    _isFAQEnabled = isFAQEnabled;
}

- (BOOL) getIsFAQEnabled{
    return self.isFAQEnabled;
}

- (void) setIsInboxEnabled:(BOOL)isInboxEnabled{
    _isInboxEnabled = isInboxEnabled;
}

- (BOOL) getIsInboxEnabled {
    return self.isInboxEnabled;
}

- (void) setIsAutoCampaignsEnabled:(BOOL)isAutoCampaignsEnabled{
    _isAutoCampaignsEnabled = isAutoCampaignsEnabled;
}

- (BOOL) getIsAutoCampaignsEnabled{
    return self.isAutoCampaignsEnabled;
}

- (void) setIsManualCampaignsEnabled:(BOOL)isManualCampaignsEnabled{
    _isManualCampaignsEnabled = isManualCampaignsEnabled;
}

- (BOOL) getIsManualCampaignsEnabled{
    return self.isManualCampaignsEnabled;
}

- (void) setIsUserEventsEnabled:(BOOL)isUserEventsEnabled{
    _isUserEventsEnabled = isUserEventsEnabled;
}

- (BOOL) getIsUserEventsEnabled{
    return self.isUserEventsEnabled;
}

- (void) setIsAOTUserCreateEnabled:(BOOL)isAOTUserCreateEnabled{
    _isAOTUserCreateEnabled = isAOTUserCreateEnabled;
}

- (BOOL) getIsAOTUserCreateEnabled{
    return self.isAOTUserCreateEnabled;
}

- (void) setShowCustomBrandBanner:(BOOL)showCustomBrandBanner{
    _showCustomBrandBanner = showCustomBrandBanner;
}

- (BOOL) getShowCustomBrandBanner {
    return self.showCustomBrandBanner;
}

- (void) setConversationConfig:(FCConversationConfig *)conversationConfig{
    _conversationConfig = conversationConfig;
}

- (FCConversationConfig *) getConversationConfig {
    return self.conversationConfig;
}

@end
