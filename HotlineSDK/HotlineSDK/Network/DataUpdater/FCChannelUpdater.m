//
//  FDChannelUpdater.m
//  HotlineSDK
//
//  Created by user on 04/11/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FCChannelUpdater.h"
#import "FCMessageServices.h"
#import "FCConstants.h"
#import "FCMacros.h"
#import "FCConversations.h"
#import "FCRemoteConfig.h"

@implementation FCChannelUpdater

-(id)init{
    self = [super init];
    if (self) {
        //[self useInterval:CHANNELS_FETCH_INTERVAL_DEFAULT];
        [self useInterval:[FCRemoteConfig sharedInstance].refreshIntervals.channelsFetchIntervalLaidback];
        [self useConfigKey:FC_CHANNELS_LAST_REQUESTED_TIME];
    }
    return self;
}

-(void)doFetch:(void(^)(NSError *error))completion{
    if([[FCRemoteConfig sharedInstance] isActiveInboxAndAccount]){
        [FCMessageServices fetchAllChannels:^(NSArray<FCChannels *> *channels, NSError *error) {
            ALog(@"Channels updated");
            if(completion) completion(error);
        }];
    }
}

@end
