//
//  FCMessageMaskConfig.m
//  FreshchatSDK
//
//  Created by Harish Kumar on 04/12/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import "FCMessageMaskConfig.h"
#import "FCUserDefaults.h"

@implementation FCMessageMaskConfig

-(instancetype)init{
    self = [super init];
    if (self) {
        self.messageMasks = [self getMessageMasks];
    }
    return self;
}

- (NSArray *) getMessageMasks {
    if ([FCUserDefaults getObjectForKey:FRESTCHAT_DEFAULTS_MESSAGE_MASK] != nil) {
        return [FCUserDefaults getObjectForKey:FRESTCHAT_DEFAULTS_MESSAGE_MASK];
    }
    return nil;
}

- (void) updateMessageMasks : (NSArray *) maskArray {
    [FCUserDefaults setObject:maskArray forKey:FRESTCHAT_DEFAULTS_MESSAGE_MASK];
    self.messageMasks = maskArray;
}

- (void) updateMessageMaskingInfo : (NSDictionary *) info {
    [self updateMessageMasks:info[@"iosMessageMasks"]];
}

@end
