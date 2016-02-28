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
#define HOTLINE_CHANNEL_ENTITY @"HLChannel"
#define HOTLINE_INDEX_ENTITY @"FDIndex"
#define ARTICLE_TITLE @"articleTitle"
#define ARTICLE_DESCRIPTION @"articleDescription"

@interface KonotorDataManager : NSObject

@property (nonatomic, strong) NSManagedObjectContext *mainObjectContext;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectContext *backgroundContext;

+(KonotorDataManager*)sharedInstance;
-(BOOL)save;
-(void)areSolutionsEmpty:(void(^)(BOOL isEmpty))handler;
-(void)deleteAllIndices:(void(^)(NSError *error))handler;
-(void)deleteAllSolutions:(void(^)(NSError *error))handler;
-(void)fetchAllSolutions:(void(^)(NSArray *solutions, NSError *error))handler;
-(void)fetchAllArticlesOfCategoryID:(NSNumber *)categoryID handler:(void(^)(NSArray *articles, NSError *error))handler;
-(void)fetchAllVisibleChannels:(void(^)(NSArray *channels, NSError *error))handler;
-(void)deleteAllChannels:(void(^)(NSError *error))handler;
-(void)deleteAllMessages:(void(^)(NSError *error))handler;
-(void)deleteAllProperties:(void(^)(NSError *error))handler;
-(void)areChannelsEmpty:(void(^)(BOOL isEmpty))handler;

@end