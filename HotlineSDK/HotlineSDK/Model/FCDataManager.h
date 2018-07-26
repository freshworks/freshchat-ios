//
//  KonotorDataManager.h
//  Konotor
//
//  Created by Vignesh G on 15/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define FRESHCHAT_CSAT_ENTITY @"FCCsat"
#define FRESHCHAT_ARTICLES_ENTITY @"FCArticles"
#define FRESHCHAT_TAGS_ENTITY @"FCTags"
#define FRESHCHAT_CATEGORIES_ENTITY @"FCCategories"
#define FRESHCHAT_CHANNELS_ENTITY @"FCChannels"
#define FRESHCHAT_FAQ_SEARCH_INDEX_ENTITY @"FCFAQSearchIndex"
#define FRESHCHAT_USER_PROPERTIES_ENTITY @"FCUserProperties"
#define FRESHCHAT_CONVERSATIONS_ENTITY @"FCConversations"
#define FRESHCHAT_MESSAGES_ENTITY @"FCMessages"
#define FRESHCHAT_MESSAGE_FRAGMENTS_ENTITY @"FCMessageFragments"
#define FRESHCHAT_MESSAGE_BINARIES_ENTITY @"FCMessageBinaries"
#define HOTLINE_USERS_ENTITY @"FCUsers"
#define FRESHCHAT_PARTICIPANTS_ENTITY @"FCParticipants"

@interface FCDataManager : NSObject

@property (nonatomic, strong) NSManagedObjectContext *mainObjectContext;
@property (nonatomic, strong) NSManagedObjectContext *backgroundContext;

+(FCDataManager*)sharedInstance;
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
-(void)deleteAllFAQ:(void(^)(NSError *error))handler;
-(void)deleteAllProperties:(void(^)(NSError *error))handler;
-(void)deleteAllCSATEntries:(void(^)(NSError *error))handler;
-(void)areChannelsEmpty:(void(^)(BOOL isEmpty))handler;
-(void)cleanUpUser:(void (^)(NSError *))mainHandler;
-(void)clearUserExceptTags:(void (^)(NSError *))mainHandler;

@end
