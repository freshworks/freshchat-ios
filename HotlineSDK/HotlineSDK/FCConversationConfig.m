//
//  FCMiscFeatures.m
//  HotlineSDK
//
//  Created by user on 06/08/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCConversationConfig.h"
#import "HLUserDefaults.h"
#import "FCRefreshIntervals.h"

@implementation FCConversationConfig

-(instancetype)init{
    self = [super init];
    if (self) {
        self.showAgentAvatars = YES;
        self.launchDeeplinkFromNotification = YES;
        self.activeConvFetchBackoffRatio = 1.25;
        self.activeConvWindow = 3 * ONE_DAY_IN_MS;
    }
    return self;
}

- (void) setShowAgentAvatars:(BOOL)showAgentAvatars {
    
    _showAgentAvatars = showAgentAvatars;
    [HLUserDefaults setBool:showAgentAvatars forKey:CONFIG_RC_AGENT_AVATAR_ENABLED];
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

- (BOOL) getLaunchDeeplinkFromNotification{
    
    return  self.launchDeeplinkFromNotification;
}

- (void) setLaunchDeeplinkFromNotification:(BOOL)launchDeeplinkFromNotification{
    _launchDeeplinkFromNotification = launchDeeplinkFromNotification;
    [HLUserDefaults setBool:launchDeeplinkFromNotification forKey:CONFIG_RC_NOTIFICATION_DEEPLINK_ENABLED];
}

- (long) getActiveConvWindow{
    
    return self.activeConvWindow;
}

- (void) setActiveConvWindow:(long)activeConvWindow{
    
    _activeConvWindow = activeConvWindow;
    [HLUserDefaults setLong:activeConvWindow forKey:CONFIG_RC_ACTIVE_CONV_WINDOW];
}

@end
