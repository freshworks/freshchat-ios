//
//  FDSolutionUpdater.m
//  FreshdeskSDK
//
//  Created by Hrishikesh on 06/11/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FDSolutionUpdater.h"
#import "FDConstants.h"
#include "FDIndex.h"
#include "FDMacros.h"
#import "FDCoreDataCoordinator.h"
#define ARTICLE_TITLE @"articleTitle"
#define ARTICLE_DESCRIPTION @"articleDescription"

@interface FDSolutionUpdater ()

@end

@implementation FDSolutionUpdater

-(id)init{
    self = [super init];
    if (self) {
        self.intervalConfigKey = MOBIHELP_DEFAULTS_SOLUTIONS_LAST_UPDATED_TIME_V2;
        self.intervalInSecs = NEW_ARTICLE_FETCH_INTERVAL;
    }
    return self;
}

-(void)doFetch:(void(^)(NSError *error))completion{
    NSManagedObjectContext *backgroundContext  = [[FDCoreDataCoordinator sharedInstance] getBackgroundContext];
    FDAPIClient *webservice = [[FDAPIClient alloc]init];
    FDCoreDataImporter *foregroundDataImporter = [[FDCoreDataImporter alloc]initWithContext:backgroundContext webservice:webservice];
    [foregroundDataImporter importAllFoldersWithParam:nil completion:^(NSError *error) {
        if (!error) {
            [self performArticleIndexing];
        }
        completion(error);
    }];
}

-(void)performArticleIndexing{
    NSManagedObjectContext *backgroundContext  = [[FDCoreDataCoordinator sharedInstance] getBackgroundContext];
    FDAPIClient *webservice = [[FDAPIClient alloc]init];
    FDCoreDataImporter *backgroundDataImporter = [[FDCoreDataImporter alloc]initWithContext:backgroundContext webservice:webservice];
    [backgroundDataImporter updateIndex];
}

-(void)noUpdate{
    [self performArticleIndexing];
}

@end
