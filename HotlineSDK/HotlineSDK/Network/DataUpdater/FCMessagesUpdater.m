//
//  FDMessagesUpdater.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 27/04/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FCMessagesUpdater.h"
#import "FCConstants.h"
#import "FCMessageServices.h"
#import "FCRemoteConfig.h"
#import "FCUserUtil.h"

@interface FCMessagesUpdater()

@end

@implementation FCMessagesUpdater

-(id)init{
    self = [super init];
    if (self) {
        //[self useInterval:MESSAGES_FETCH_INTERVAL_DEFAULT];
        [self useInterval:[FCRemoteConfig sharedInstance].refreshIntervals.msgFetchIntervalLaidback];
        [self useConfigKey:FC_CONVERSATIONS_LAST_REQUESTED_TIME];
    }
    return self;
}

-(void)doFetch:(void(^)(NSError *error))completion{
    [FCMessageServices fetchMessagesForSrc:self.requestSource andCompletion:completion];
}

- (void) resetTime{
    // This is set to 1 to not trigger the restore case. #damn
    //TODO: Hacky .. We need to do a better way - Rex
    [self resetTimeTo:@(1)];
}

@end
