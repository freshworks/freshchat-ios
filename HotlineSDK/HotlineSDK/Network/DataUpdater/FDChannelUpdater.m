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
#import "KonotorConversation.h"

@implementation FDChannelUpdater

-(id)init{
    self = [super init];
    if (self) {
        self.intervalInSecs = CHANNELS_FETCH_INTERVAL;
        self.intervalConfigKey = HOTLINE_DEFAULTS_CHANNELS_LAST_UPDATED_INTERVAL_TIME;
    }
    return self;
}

-(void)doFetch:(void(^)(NSError *error))completion{
    [HLMessageServices fetchMessagesWithChannel:YES handler:nil];
}

@end
