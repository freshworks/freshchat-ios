//
//  FreshchatConfig.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 12/12/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FreshchatSDK.h"
#import "FCTheme.h"
#import "FCLocalization.h"
#import "FDThemeConstants.h"

@implementation FreshchatConfig

-(instancetype)initWithAppID:(NSString *)appID andAppKey:(NSString *)appKey{
    self = [super init];
    if (self) {
        self.domain = @"msdk.freshchat.com";
        self.stringsBundle = DEFAULT_BUNDLE_NAME;
        self.appID = appID;
        self.appKey = appKey;
        self.themeName = FD_DEFAULT_THEME_NAME;
        self.gallerySelectionEnabled = YES;
        self.teamMemberInfoVisible = YES;
        self.notificationSoundEnabled = YES;
        self.cameraCaptureEnabled = YES;
        self.showNotificationBanner = YES;
        self.responseExpectationVisible = YES;
        self.eventsUploadEnabled = YES;
        self.hybridExperienceEnabled = NO;
    }
    return self;
}

@end
