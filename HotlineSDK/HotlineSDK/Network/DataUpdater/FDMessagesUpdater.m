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
#import "FCRemoteConfigUtil.h"

@interface FDMessagesUpdater()

@end

@implementation FDMessagesUpdater

-(id)init{
    self = [super init];
    if (self) {
        //[self useInterval:MESSAGES_FETCH_INTERVAL_DEFAULT];
        [self useInterval:[FCRemoteConfigUtil getMsgFetchIntervalLaidback]];
        [self useConfigKey:HOTLINE_DEFAULTS_CONVERSATIONS_LAST_UPDATED_INTERVAL_TIME];
    }
    return self;
}

-(void)doFetch:(void(^)(NSError *error))completion{
    if([FCRemoteConfigUtil isActiveInboxAndAccount]){
        [HLMessageServices fetchMessagesForSrc:self.requestSource andCompletion:completion];
    }
}

- (void) resetTime{
    // This is set to 1 to not trigger the restore case. #damn
    //TODO: Hacky .. We need to do a better way - Rex
    [self resetTimeTo:@(1)];
}

@end
