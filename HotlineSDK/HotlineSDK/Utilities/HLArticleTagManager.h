//
//  HLArticleTagManager.h
//  HotlineSDK
//
//  Created by Hrishikesh on 23/06/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#ifndef HLArticleTagManager_h
#define HLArticleTagManager_h

#import "KonotorDataManager.h"
#import <Foundation/Foundation.h>

@interface HLArticleTagManager : NSObject

+(instancetype)sharedInstance;

-(void)addTag:(NSString *)tag forArticleId: (NSNumber *)articleId;
-(void)removeTagsForArticleId: (NSNumber *)articleId;
-(void)articlesForTags:(NSArray *) tags withCompletion:(void (^)(NSSet *))completion;

-(void) getArticleForTags : (NSArray *)tags inContext :(NSManagedObjectContext *)context withCompletion:(void (^)(NSArray *))completion;
-(void) getChannelsForTags : (NSArray *)tags inContext : (NSManagedObjectContext *) context withCompletion:(void (^)(NSArray *))completion;
-(void) getCategoriesForTags : (NSArray *)tags inContext : (NSManagedObjectContext *) context withCompletion:(void (^)(NSArray *))completion;

-(void) save;
-(void) clear;

@end

#endif /* HLArticleTagManager_h */
