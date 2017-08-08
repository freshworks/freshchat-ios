//
//  FDDAUUpdater.m
//  HotlineSDK
//
//  Created by Hrishikesh on 14/05/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FDDAUUpdater.h"
#import "HLConstants.h"
#import "HLCoreServices.h"
#import "FCRemoteConfigUtil.h"
#import "HLUser.h"

@implementation FDDAUUpdater

-(id)init{
    self = [super init];
    if (self) {
        [self useInterval:[FCRemoteConfigUtil getSessionDuration]];
        [self useConfigKey:HOTLINE_DEFAULTS_DAU_LAST_UPDATED_INTERVAL_TIME];
    }
    return self;
}

-(void)doFetch:(void(^)(NSError *error))completion{
    if([HLUser isUserRegistered] && [FCRemoteConfigUtil isAccountActive]){
        [HLCoreServices DAUCall:^(NSError *error) {
            if(completion){
                completion(error);
            }
        }];
    }
}
@end
