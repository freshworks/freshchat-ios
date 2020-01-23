//
//  FCRemoteConfig.m
//  HotlineSDK
//
//  Created by user on 25/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCRemoteConfig.h"
#import "FCSecureStore.h"
#import "FCMessages.h"


@implementation FCRemoteConfig

+(instancetype)sharedInstance{
    static FCRemoteConfig *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}


- (instancetype)init{
    self = [super init];
    if (self) {
        self.conversationConfig             = [[FCConversationConfig alloc] init];
        self.refreshIntervals               = [[FCRefreshIntervals alloc] init];
        self.enabledFeatures                = [[FCEnabledFeatures alloc] init];
        self.accountActive                  = [self getDefaultAccountActive];
        self.sessionTimeOutInterval         = [self getDefaultSessionTimeOutInterval];
        self.csatSettings                   = [[FCCSatSettings alloc]init];
        self.userAuthConfig                 = [[FCUserAuthConfig alloc] init];
        self.messageMaskConfig              = [[FCMessageMaskConfig alloc] init];
        self.unsupportedFragErrMsg          = [[FCUnsupportedFragmentErrorMsgs alloc] init];
        self.eventsConfig                   = [[FCEventsConfig alloc] init];
    }
    return self;
}

-(BOOL) getDefaultAccountActive {
    if ([FCUserDefaults getObjectForKey:CONFIG_RC_IS_ACCOUNT_ACTIVE] != nil) {
        return [FCUserDefaults getBoolForKey:CONFIG_RC_IS_ACCOUNT_ACTIVE];
    }
    return YES;
}


- (long) getDefaultSessionTimeOutInterval {
    if ([FCUserDefaults getObjectForKey:CONFIG_RC_SESSION_TIMEOUT_INTERVAL] != nil) {
        return [FCUserDefaults getLongForKey:CONFIG_RC_SESSION_TIMEOUT_INTERVAL];
    }
    return 30 * ONE_MINUTE_IN_MS;
}

- (void) updateAccountActive:(BOOL)accountActive {
    [FCUserDefaults setBool:accountActive forKey:CONFIG_RC_IS_ACCOUNT_ACTIVE];
    self.accountActive = accountActive;
}

- (void) updateSessionTimeOutInterval:(long) sessionTimeOutInterval {
    [FCUserDefaults setLong:sessionTimeOutInterval forKey:CONFIG_RC_SESSION_TIMEOUT_INTERVAL];
    self.sessionTimeOutInterval = sessionTimeOutInterval;
}

- (void) updateRemoteConfig : (NSDictionary *) configDict {
    NSArray *enabledFeaturesArray       = [configDict objectForKey:@"enabledFeatures"];
    NSDictionary *refreshIntervalsDict  = [configDict objectForKey:@"refreshIntervals"];
    NSDictionary *convConfigDict        = [configDict objectForKey:@"conversationConfig"];
    NSDictionary *csatSettingsDict      = [configDict objectForKey:@"csatSettings"];
    NSDictionary *unsupportedMsgErrDict = [configDict objectForKey:@"unsupportedFragmentConfig"];
    NSDictionary *userAuthConfig     = [configDict objectForKey:@"userAuthConfig"];
    NSDictionary *messageMaskingConfigDict  = [configDict objectForKey:@"messageMaskingConfig"];
    NSDictionary *eventsConfigDict         = [configDict objectForKey:@"eventsConfig"];
    
    [self updateAccountActive:[[configDict objectForKey:@"accountActive"] boolValue]];
    [self updateSessionTimeOutInterval:[[configDict objectForKey:@"sessionTimeoutInterval"] longValue]];
    
    if (convConfigDict != nil) {
        [self.conversationConfig updateConvConfig:convConfigDict];
    }
    if (enabledFeaturesArray != nil) {
        [self.enabledFeatures updateConvConfig:enabledFeaturesArray];
    }
    if (refreshIntervalsDict != nil) {
        [self.refreshIntervals updateRefreshConfig:refreshIntervalsDict];
    }
    if (csatSettingsDict != nil) {
        [self.csatSettings updateCSatConfig:csatSettingsDict];
    }

    if (unsupportedMsgErrDict != nil) {
        [self.unsupportedFragErrMsg updateUnsupportedFragmentMsgInfo:unsupportedMsgErrDict];
    }
    
    if(messageMaskingConfigDict != nil) {
        [self.messageMaskConfig updateMessageMaskingInfo:messageMaskingConfigDict];
    }
    
    if (userAuthConfig != nil) {
        [self.userAuthConfig updateUserAuthConfig:userAuthConfig];
    }
    
    if (eventsConfigDict != nil) {
        [self.eventsConfig updateEventsConfig:eventsConfigDict];
    }
}

- (BOOL) isActiveInboxAndAccount {
    return self.accountActive && self.enabledFeatures.inboxEnabled;
}

- (BOOL) isActiveFAQAndAccount {
    return self.accountActive && self.enabledFeatures.faqEnabled;
}

- (BOOL) isUserAuthEnabled {
    return (self.userAuthConfig.isjwtAuthEnabled
            && self.userAuthConfig.isStrictModeEnabled);
}

- (BOOL) isActiveConvAvailable{
    long days = [FCMessages daysSinceLastMessageInContext: [[FCDataManager sharedInstance] mainObjectContext]];
    if( days * ONE_SECONDS_IN_MS < self.conversationConfig.activeConvWindow ){
        return true;
    }
    return false;
}


@end
