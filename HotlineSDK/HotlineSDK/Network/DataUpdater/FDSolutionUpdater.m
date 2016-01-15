//
//  FDSolutionUpdater.m
//  FreshdeskSDK
//
//  Created by Hrishikesh on 06/11/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FDSolutionUpdater.h"
#import "HLConstants.h"
#import "HLMacros.h"
#import "KonotorDataManager.h"
#import "HLFAQServices.h"

@interface FDSolutionUpdater ()

@end

@implementation FDSolutionUpdater

-(id)init{
    self = [super init];
    if (self) {
        self.intervalInSecs = SOLUTIONS_FETCH_INTERVAL;
        self.intervalConfigKey = HOTLINE_DEFAULTS_SOLUTIONS_LAST_UPDATED_TIME;
    }
    return self;
}

-(void)doFetch:(void(^)(NSError *error))completion{
    HLFAQServices *service = [[HLFAQServices alloc]init];
    [service fetchAllCategories];
}

@end
