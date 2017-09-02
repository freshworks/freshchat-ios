//
//  FDSessionUpdater.m
//  HotlineSDK
//
//  Created by Hrishikesh on 14/05/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FDSessionUpdater.h"
#import "HLConstants.h"
#import "HLCoreServices.h"


@implementation FDSessionUpdater

-(id)init{
    self = [super init];
    if (self) {
        [self useInterval:SESSION_UPDATE_INTERVAL];
        [self useConfigKey:HOTLINE_DEFAULTS_DAU_LAST_UPDATED_INTERVAL_TIME];
    }
    return self;
}

-(void)doFetch:(void(^)(NSError *error))completion{
    [HLCoreServices performSessionCall:^(NSError *error) {
        if(completion){
            completion(error);
        }
    }];
}

@end
