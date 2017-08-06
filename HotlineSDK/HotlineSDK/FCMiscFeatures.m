//
//  FCMiscFeatures.m
//  HotlineSDK
//
//  Created by user on 06/08/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCMiscFeatures.h"

@implementation FCMiscFeatures

-(instancetype)init{
    self = [super init];
    if (self) {
        self.showAgentAvatars = YES;
        self.showRealAgentAvatars = YES;
        self.launchDeeplinkFromNotification = YES;
    }
    return self;
}

- (void) setShowAgentAvatars:(BOOL)showAgentAvatars {
    
    _showAgentAvatars = showAgentAvatars;
}

- (BOOL) getShowAgentAvatars {
    
    return self.showAgentAvatars;
}

- (void) setShowRealAgentAvatars:(BOOL)showRealAgentAvatars {
    
    _showRealAgentAvatars = showRealAgentAvatars;
}

- (BOOL) getshowRealAgentAvatars {
    
    return self.showRealAgentAvatars;
}

- (void) setLaunchDeeplinkFromNotification:(BOOL)launchDeeplinkFromNotification{
    _launchDeeplinkFromNotification = launchDeeplinkFromNotification;
}

- (BOOL) getLaunchDeeplinkFromNotification{
    
    return  self.launchDeeplinkFromNotification;
}

@end
