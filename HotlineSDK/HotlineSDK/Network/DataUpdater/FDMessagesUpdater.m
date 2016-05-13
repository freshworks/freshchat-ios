//
//  FDMessagesUpdater.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 27/04/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FDMessagesUpdater.h"
#import "HLConstants.h"
#import "HLMessageServices.h"

@interface FDMessagesUpdater()

@end

@implementation FDMessagesUpdater

-(id)init{
    self = [super init];
    if (self) {
        self.intervalInSecs = MESSAGES_FETCH_INTERVAL;
        self.intervalConfigKey = HOTLINE_DEFAULTS_CONVERSATIONS_LAST_UPDATED_INTERVAL_TIME;
    }
    return self;
}

-(void)doFetch:(void(^)(NSError *error))completion{
    [HLMessageServices fetchMessages:completion];
}

- (void) resetTime{
    [self.secureStore setObject:@(1) forKey:self.intervalConfigKey]; //TODO: Hacky .. We need to do a better way - Rex
}

@end