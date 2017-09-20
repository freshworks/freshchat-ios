//
//  FDChannelUpdater.m
//  HotlineSDK
//
//  Created by user on 04/11/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDChannelUpdater.h"
#import "HLMessageServices.h"
#import "HLConstants.h"
#import "HLMacros.h"
#import "KonotorConversation.h"

@implementation FDChannelUpdater

-(id)init{
    self = [super init];
    if (self) {
        [self useInterval:CHANNELS_FETCH_INTERVAL_DEFAULT];
        [self useConfigKey:HOTLINE_DEFAULTS_CHANNELS_LAST_UPDATED_INTERVAL_TIME];
    }
    return self;
}

-(void)doFetch:(void(^)(NSError *error))completion{
    [HLMessageServices fetchAllChannels:^(NSArray<HLChannel *> *channels, NSError *error) {
        ALog(@"Channels updated");
        if(completion) completion(error);
    }];
}

@end
