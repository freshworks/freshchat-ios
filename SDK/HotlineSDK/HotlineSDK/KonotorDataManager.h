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
#define HOTLINE_CATEGORY_ENTITY @"HLCategory"
#define HOTLINE_INDEX_ENTITY @"FDIndex"
#define ARTICLE_TITLE @"articleTitle"
#define ARTICLE_DESCRIPTION @"articleDescription"

@interface KonotorDataManager : NSObject

@property (nonatomic, readonly, retain) NSManagedObjectModel *objectModel;
@property (nonatomic, readonly, retain) NSManagedObjectContext *mainObjectContext;
@property (nonatomic, readonly, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectContext *backgroundContext;

+(KonotorDataManager*)sharedInstance;
-(BOOL)save;
-(void)areSolutionsEmpty:(void(^)(BOOL isEmpty))handler;
-(void)deleteAllSolutions:(void(^)(NSError *error))handler;
-(void)fetchAllSolutions:(void(^)(NSArray *solutions, NSError *error))handler;
-(void)deleteAllIndices;

@end


