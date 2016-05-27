//
//  HotlineConfig.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 12/12/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Hotline.h"
#import "HLTheme.h"

@implementation HotlineConfig

-(instancetype)initWithAppID:(NSString *)appID andAppKey:(NSString *)appKey{
    self = [super init];
    if (self) {
        self.domain = @"app.hotline.io";
        self.stringsBundle = @"HLLocalization";
        self.appID = appID;
        self.appKey = appKey;
        self.themeName = @"HLTheme";
        self.pictureMessagingEnabled = YES;
        self.voiceMessagingEnabled = NO;
        self.agentAvatarEnabled = YES;
        self.notificationSoundEnabled = YES;
        self.displayFAQsAsGrid = YES;
        self.cameraCaptureEnabled = YES;
        self.showNotificationBanner = YES;
        self.pollWhenAppActive = NO;
    }
    return self;
}

@end