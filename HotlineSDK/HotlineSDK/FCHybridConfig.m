//
//  FCHybridConfig.m
//  FreshchatSDK
//
//  Created by Harish kumar on 03/03/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import "FCHybridConfig.h"
#import "FCUserDefaults.h"
#import "FCStringUtil.h"

@implementation FCHybridConfig

-(instancetype)init{
    self = [super init];
    if (self) {
        self.webAppEnabled = [self hasWebAppEnabled];
        self.webAppUrl = [self getWebAppUrl];
    }
    return self;
}

- (BOOL) hasWebAppEnabled {
    return [FCUserDefaults getBoolForKey:CONFIG_RC_HYBRID_WEB_APP_ENABLED];
}

- (NSString *) getWebAppUrl {
    return [FCUserDefaults getStringForKey:CONFIG_RC_HYBRID_WEB_APP_URL];
}

- (void) updateWebAppEnabled : (BOOL) status{
    [FCUserDefaults setBool:status forKey:CONFIG_RC_HYBRID_WEB_APP_ENABLED];
    self.webAppEnabled = status;
}

- (void) updateWebAppUrl : (NSString *) webAppUrl {
    [FCUserDefaults setString:webAppUrl forKey:CONFIG_RC_HYBRID_WEB_APP_URL];
    self.webAppUrl = webAppUrl;
}

- (void) updateHybridConfig : (NSDictionary *) info {
    [self updateWebAppEnabled:[info[@"webAppEnabled"] boolValue]];
    [self updateWebAppUrl:info[@"webAppUrl"]];
}

@end
