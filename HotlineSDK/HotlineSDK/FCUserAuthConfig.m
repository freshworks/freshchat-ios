//
//  FCUserAuthConfig.m
//  FreshchatSDK
//
//  Created by Harish Kumar on 08/10/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import "FCUserAuthConfig.h"
#import "FCUserDefaults.h"

@implementation FCUserAuthConfig

-(instancetype)init{
    self = [super init];
    if (self) {
        self.isjwtAuthEnabled = [self isjwtAuthEnabled];
        self.isStrictModeEnabled = [self isStrictModeEnabled];
    }
    return self;
}

- (BOOL) isjwtAuthEnabled {
    if ([FCUserDefaults getObjectForKey:CONFIG_RC_JWT_AUTH_ENABLED] != nil) {
        return [FCUserDefaults getBoolForKey:CONFIG_RC_JWT_AUTH_ENABLED];
    }
    return FALSE;
}

- (BOOL) isStrictModeEnabled {
    if ([FCUserDefaults getObjectForKey:CONFIG_RC_JWT_AUTH_STRICT_MODE_ENABLED] != nil) {
        return [FCUserDefaults getBoolForKey:CONFIG_RC_JWT_AUTH_STRICT_MODE_ENABLED];
    }
    return FALSE;
}

- (void) updateUserAuthConfig : (NSDictionary *) info {
    [FCUserDefaults setBool:[info[@"jwtAuthEnabled"] boolValue] forKey:CONFIG_RC_JWT_AUTH_ENABLED];
    [FCUserDefaults setBool:[info[@"strictModeEnabled"] boolValue] forKey:CONFIG_RC_JWT_AUTH_STRICT_MODE_ENABLED];
}

@end
