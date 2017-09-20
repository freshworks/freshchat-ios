//
//  FCFeatures.m
//  HotlineSDK
//
//  Created by user on 27/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCEnabledFeatures.h"
#import "FDSecureStore.h"

@implementation FCEnabledFeatures


+ (instancetype)sharedInstance {
    static FCEnabledFeatures *sharedFCEnabledFeatures = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedFCEnabledFeatures = [[self alloc]init];
    });
    return sharedFCEnabledFeatures;
}

-(instancetype)init{
    self = [super init];
    if (self) {
        self.faqEnabled = [self getDefaultValue:faq];
        self.inboxEnabled = [self getDefaultValue:inbox];
        self.autoCampaignsEnabled = [self getDefaultValue:autoCampaigns];
        self.manualCampaignsEnabled = [self getDefaultValue:manualCampaigns];
        self.userEventsEnabled = [self getDefaultValue:userEvents];
        self.aotUserCreateEnabled = [self getDefaultValue:aotUserCreate];
        self.showCustomBrandBanner = [self getDefaultValue:showCustomBrandBanner];
    }
    return self;
}

-(BOOL) getDefaultValue:(enum FCEnabledFeatureType) type {
    switch (type) {
        case faq:
            if ([[FDSecureStore sharedInstance] objectForKey:FRESHCHAT_CONFIG_RC_FAQ_ENABLED] != nil ) {
                return [[FDSecureStore sharedInstance] boolValueForKey:FRESHCHAT_CONFIG_RC_FAQ_ENABLED];
            }
            return YES;
            break;
        case inbox:
            if ([[FDSecureStore sharedInstance] objectForKey:FRESHCHAT_CONFIG_RC_INBOX_ENABLED] != nil ) {
                return [[FDSecureStore sharedInstance] boolValueForKey:FRESHCHAT_CONFIG_RC_INBOX_ENABLED];
            }
            return YES;
            break;
        case autoCampaigns:
            if ([[FDSecureStore sharedInstance] objectForKey:FRESHCHAT_CONFIG_RC_AUTO_CAMPAIGNS_ENABLED] != nil ) {
                return [[FDSecureStore sharedInstance] boolValueForKey:FRESHCHAT_CONFIG_RC_AUTO_CAMPAIGNS_ENABLED];
            }
            return NO;
            break;
        case manualCampaigns:
            if ([[FDSecureStore sharedInstance] objectForKey:FRESHCHAT_CONFIG_RC_MANUAL_CAMPAIGNS_ENABLED] != nil ) {
                return [[FDSecureStore sharedInstance] boolValueForKey:FRESHCHAT_CONFIG_RC_MANUAL_CAMPAIGNS_ENABLED];
            }
            return NO;
            break;
        case userEvents:
            if ([[FDSecureStore sharedInstance] objectForKey:FRESHCHAT_CONFIG_RC_USER_EVENTS_ENABLED] != nil ) {
                return [[FDSecureStore sharedInstance] boolValueForKey:FRESHCHAT_CONFIG_RC_USER_EVENTS_ENABLED];
            }
            return NO;
            break;
        case aotUserCreate:
            if ([[FDSecureStore sharedInstance] objectForKey:FRESHCHAT_CONFIG_RC_AOT_USER_CREATE_ENABLED] != nil ) {
                return [[FDSecureStore sharedInstance] boolValueForKey:FRESHCHAT_CONFIG_RC_AOT_USER_CREATE_ENABLED];
            }
            return NO;
            break;
        case showCustomBrandBanner:
            if ([[FDSecureStore sharedInstance] objectForKey:FRESHCHAT_CONFIG_RC_CUSTOM_BRAND_BANNER_ENABLED] != nil ) {
                return [[FDSecureStore sharedInstance] boolValueForKey:FRESHCHAT_CONFIG_RC_CUSTOM_BRAND_BANNER_ENABLED];
            }
            return YES;
            break;
    }
}

-(void) updateValue:(NSString *)value {
    if ([value isEqual: @"FAQ"]) {
        self.faqEnabled = YES;
        [[FDSecureStore sharedInstance] setBoolValue:YES forKey:FRESHCHAT_CONFIG_RC_FAQ_ENABLED];
    }
    else if ([value isEqual: @"INBOX"]) {
        self.inboxEnabled = YES;
        [[FDSecureStore sharedInstance] setBoolValue:YES forKey:FRESHCHAT_CONFIG_RC_INBOX_ENABLED];
    } else if ([value isEqual: @"AUTO_CAMPAIGNS"]) {
        self.autoCampaignsEnabled = YES;
        [[FDSecureStore sharedInstance] setBoolValue:YES forKey:FRESHCHAT_CONFIG_RC_AUTO_CAMPAIGNS_ENABLED];
    } else if ([value isEqual: @"MANUAL_CAMPAIGNS"]) {
        self.manualCampaignsEnabled = YES;
        [[FDSecureStore sharedInstance] setBoolValue:YES forKey:FRESHCHAT_CONFIG_RC_MANUAL_CAMPAIGNS_ENABLED];
    } else if ([value isEqual: @"USER_EVENTS"]) {
        self.userEventsEnabled = YES;
        [[FDSecureStore sharedInstance] setBoolValue:YES forKey:FRESHCHAT_CONFIG_RC_USER_EVENTS_ENABLED];
    } else if ([value isEqual: @"AOT_USER_CREATE"]) {
        self.aotUserCreateEnabled = YES;
        [[FDSecureStore sharedInstance] setBoolValue:YES forKey:FRESHCHAT_CONFIG_RC_AOT_USER_CREATE_ENABLED];
    } else if ([value isEqual: @"CUSTOM_BRAND_BANNER"]) {
        self.showCustomBrandBanner = YES;
        [[FDSecureStore sharedInstance] setBoolValue:YES forKey:FRESHCHAT_CONFIG_RC_CUSTOM_BRAND_BANNER_ENABLED];
    }
}

- (void) updateConvConfig : (NSArray *) configDict {
    for(int i=0; i<configDict.count; i++) {
        [self updateValue:configDict[i]];
    }
}


@end
