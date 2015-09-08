//
//  FDConfigUpdater.m
//  FreshdeskSDK
//
//  Created by Hrishikesh on 06/11/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FDConfigUpdater.h"
#import "FDConstants.h"
#import "FDCoreDataCoordinator.h"

@implementation FDConfigUpdater

-(id)init{
    self = [super init];
    if (self) {
        [self setIntervalConfigKey:MOBIHELP_DEFAULTS_APP_CONFIG_LAST_UPDATED_TIME];
        [self setIntervalInSecs:CONFIG_FETCH_INTERVAL];
    }
    return self;
}

-(void)doFetch:(void(^)(NSError *error))completion{
    NSManagedObjectContext *context  = self.database.context;
    FDAPIClient *webservice         = [[FDAPIClient alloc]init];
    FDCoreDataImporter *dataImporter = [[FDCoreDataImporter alloc]initWithContext:context webservice:webservice];
    [dataImporter fetchAppConfigWithCompletion:^(NSError * error) {
        completion(error);
    }];
}

@end
