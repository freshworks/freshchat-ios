//
//  FDTicketsUpdater.m
//  FreshdeskSDK
//
//  Created by Hrishikesh on 06/11/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FDTicketsUpdater.h"
#import "FDConstants.h"
#import "FDCoreDataCoordinator.h"

@implementation FDTicketsUpdater

-(id)init{
    self = [super init];
    if (self) {
        [self setIntervalInSecs:TICKET_LIST_FETCH_INTERVAL];
        [self setIntervalConfigKey:MOBIHELP_DEFAULTS_TICKETS_LAST_UPDATED_TIME];
    }
    return self;
}

-(void)doFetch:(void (^)(NSError *))completion{
    NSManagedObjectContext *context = [[FDCoreDataCoordinator sharedInstance] getBackgroundContext];
    FDAPIClient *webservice = [[FDAPIClient alloc]init];
    FDCoreDataImporter *coreDataImporter = [[FDCoreDataImporter alloc] initWithContext:context webservice:webservice];
    [coreDataImporter updateExistingTicketsWithParam:nil completion:completion];
}

@end