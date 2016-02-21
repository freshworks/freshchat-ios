//
//  HotlineConfig.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 12/12/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Hotline.h"


@implementation HotlineConfig

-(instancetype)initWithAppID:(NSString *)appID andAppKey:(NSString *)appKey{
    self = [super init];
    if (self) {
        self.domain = @"app.hotline.io";
        self.appID = appID;
        self.appKey = appKey;
        self.pictureMessagingEnabled = YES;
        self.voiceMessagingEnabled = YES;
        self.agentAvatarEnabled = YES;
        self.notificationSoundEnabled = YES;
        self.displaySolutionsAsGrid = YES;
        self.cameraCaptureEnabled = YES;
        self.showNotificationBanner = YES;
    }
    return self;
}

@end
