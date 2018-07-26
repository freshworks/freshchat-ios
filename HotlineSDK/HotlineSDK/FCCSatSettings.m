//
//  FCCSatSettings.m
//  FreshchatSDK
//
//  Created by Harish Kumar on 20/06/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import "FCCSatSettings.h"
#import "FCUserDefaults.h"
#import "FCRefreshIntervals.h"

@implementation FCCSatSettings

-(instancetype)init{
    self = [super init];
    if (self) {
        self.maximumUserSurveyViewMillis = [self getMaximumUserSurveyViewMillis];
        self.isUserCsatViewTimerEnabled = [self getUserCsatViewTimerState];
    }
    return self;
}

- (long) getMaximumUserSurveyViewMillis{
    if ([FCUserDefaults getObjectForKey:CONFIG_RC_MAXIMUM_USER_SURVEY_VIEW_MILLIS] != nil) {
        return [FCUserDefaults getLongForKey:CONFIG_RC_MAXIMUM_USER_SURVEY_VIEW_MILLIS];
    }
    return 0;
}

- (BOOL) getUserCsatViewTimerState {
    if ([FCUserDefaults getObjectForKey:CONFIG_RC_USER_CSAT_VIEW_TIMER_ENABLED] != nil) {
        return [FCUserDefaults getBoolForKey:CONFIG_RC_USER_CSAT_VIEW_TIMER_ENABLED];
    }
    return FALSE;
}

- (void) updateCSatConfig : (NSDictionary *) info {
    [FCUserDefaults setBool:[info[@"userCsatViewTimer"] boolValue] forKey:CONFIG_RC_USER_CSAT_VIEW_TIMER_ENABLED];
    [FCUserDefaults setLong:[info[@"maximumUserSurveyViewMillis"] longValue] forKey:CONFIG_RC_MAXIMUM_USER_SURVEY_VIEW_MILLIS];
}

@end
