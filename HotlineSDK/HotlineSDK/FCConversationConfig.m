//
//  FCMiscFeatures.m
//  HotlineSDK
//
//  Created by user on 06/08/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCConversationConfig.h"
#import "HLUserDefaults.h"

@implementation FCConversationConfig

-(instancetype)init{
    self = [super init];
    if (self) {
        self.showAgentAvatars = YES;
        self.launchDeeplinkFromNotification = YES;
        self.activeConvFetchBackoffRatio = 1.25;
    }
    return self;
}

- (void) setShowAgentAvatars:(BOOL)showAgentAvatars {
    
    _showAgentAvatars = showAgentAvatars;
}

- (BOOL) getShowAgentAvatars {
    
    return self.showAgentAvatars;
}

- (double) getActiveConvFetchBackoffRatio{
    
    return self.activeConvFetchBackoffRatio;
}

- (void) setActiveConvFetchBackoffRatio:(float)activeConvFetchBackoffRatio{
    
    [HLUserDefaults setFloat:activeConvFetchBackoffRatio forKey:CONFIG_RC_ACTIVE_CONV_FETCH_BACKOFF_RATIO];
    _activeConvFetchBackoffRatio = activeConvFetchBackoffRatio;
}

- (void) setLaunchDeeplinkFromNotification:(BOOL)launchDeeplinkFromNotification{
    _launchDeeplinkFromNotification = launchDeeplinkFromNotification;
}

- (BOOL) getLaunchDeeplinkFromNotification{
    
    return  self.launchDeeplinkFromNotification;
}

@end
