//
//  FDSolutionUpdater.m
//  FreshdeskSDK
//
//  Created by Hrishikesh on 06/11/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCSolutionUpdater.h"
#import "FCConstants.h"
#import "FCMacros.h"
#import "FCDataManager.h"
#import "FCFAQServices.h"
#import "FCRemoteConfig.h"

@interface FCSolutionUpdater ()

@end

@implementation FCSolutionUpdater

-(id)init{
    self = [super init];
    if (self) {
        //[self useInterval:SOLUTIONS_FETCH_INTERVAL_DEFAULT];
        [self useInterval:[FCRemoteConfig sharedInstance].refreshIntervals.faqFetchIntervalLaidback];
        [self useConfigKey:FC_SOLUTIONS_LAST_REQUESTED_TIME];
    }
    return self;
}

-(void)doFetch:(void(^)(NSError *error))completion{
    if([[FCRemoteConfig sharedInstance] isActiveFAQAndAccount]){
        FCFAQServices *service = [[FCFAQServices alloc]init];
        [service fetchAllCategories:^(NSError *error) {
            ALog(@"Solution updated");
            if(completion){
                completion(error);
            }
        }];
    }
}

@end
