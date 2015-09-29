//
//  KonotorDataManager.h
//  Konotor
//
//  Created by Vignesh G on 15/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

extern NSString * const DataManagerDidSaveNotification;
extern NSString * const DataManagerDidSaveFailedNotification;

#define HOTLINE_ARTICLE_ENTITY @"HLArticle"
#define HOTLINE_CATEGORY_ENTITY  @"HLCategory"

@interface KonotorDataManager : NSObject

@property (nonatomic, readonly, retain) NSManagedObjectModel *objectModel;
@property (nonatomic, readonly, retain) NSManagedObjectContext *mainObjectContext;
@property (nonatomic, readonly, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (KonotorDataManager*)sharedInstance;
- (BOOL)save;
- (NSManagedObjectContext*)managedObjectContext;
-(void)deleteAllSolutions;

@end


