//
//  coreDataCoordinator.h
//  FreshdeskSDK
//
//  Created by kirthikas on 23/03/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface FDCoreDataCoordinator : NSObject

@property (nonatomic, strong) NSManagedObjectContext *mainContext;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSFileManager *fileManager;

+(id)sharedInstance;

-(NSManagedObjectContext*) getBackgroundContext;

@end