//
//  KonotorDataManager.h
//  Konotor
//
//  Created by Vignesh G on 15/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define HOTLINE_CSAT_ENTITY @"HLCsat"
#define HOTLINE_ARTICLE_ENTITY @"HLArticle"
#define HOTLINE_TAGS_ENTITY @"HLTags"
#define HOTLINE_CATEGORY_ENTITY @"HLCategory"
#define HOTLINE_CHANNEL_ENTITY @"HLChannel"
#define HOTLINE_INDEX_ENTITY @"FDIndex"
#define HOTLINE_CUSTOM_PROPERTY_ENTITY @"KonotorCustomProperty"
#define HOTLINE_CONVERSATION_ENTITY @"KonotorConversation"
#define HOTLINE_MESSAGE_ENTITY @"KonotorMessage"
#define HOTLINE_MESSAGE_BINARY_ENTITY @"KonotorMessageBinary"
#define HOTLINE_USER_ENTITY @"KonotorUser"

@interface KonotorDataManager : NSObject

@property (nonatomic, strong) NSManagedObjectContext *mainObjectContext;
@property (nonatomic, strong) NSManagedObjectContext *backgroundContext;

+(KonotorDataManager*)sharedInstance;
-(BOOL)isReady;
-(BOOL)save;
-(void)areSolutionsEmpty:(void(^)(BOOL isEmpty))handler;
-(void)deleteAllIndices:(void(^)(NSError *error))handler;
-(void)deleteAllSolutions:(void(^)(NSError *error))handler;
-(void) fetchAllCategoriesForTags  :(NSArray*) tagsIds withCompletion :(void(^)(NSArray *solutions, NSError *error))handler;
-(void) fetchAllCategoriesWithCompletion :(void(^)(NSArray *solutions, NSError *error))handler;
-(void)fetchAllArticlesOfCategoryID:(NSNumber *)categoryID handler:(void(^)(NSArray *articles, NSError *error))handler;
-(void) fetchAllVisibleChannelsForTags:(NSArray *)channelsIds hasTags:(BOOL)containstags   completion:(void (^)(NSArray *channelInfos, NSError *))handler;
-(void) fetchAllVisibleChannelsWithCompletion:(void (^)(NSArray *channelInfos, NSError *))handler;
-(void)deleteAllChannels:(void(^)(NSError *error))handler;
-(void)deleteAllMessages:(void(^)(NSError *error))handler;
-(void)deleteAllProperties:(void(^)(NSError *error))handler;
-(void)deleteAllCSATEntries:(void(^)(NSError *error))handler;
-(void)areChannelsEmpty:(void(^)(BOOL isEmpty))handler;
-(void)cleanUpUser:(void (^)(NSError *))mainHandler;

@end
