//
//  HLTagManager.h
//  HotlineSDK
//
//  Created by Hrishikesh on 23/06/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#ifndef HLTagManager_h
#define HLTagManager_h

#import "KonotorDataManager.h"
#import <Foundation/Foundation.h>

@interface HLTagManager : NSObject

+(instancetype)sharedInstance;

-(void)addTag:(NSString *)tag forArticleId: (NSNumber *)articleId;
-(void)removeTagsForArticleId: (NSNumber *)articleId;
-(void)articlesForTags:(NSArray *) tags withCompletion:(void (^)(NSSet *))completion;

-(void) getArticlesForTags : (NSArray *)tags inContext :(NSManagedObjectContext *)context withCompletion:(void (^)(NSArray *))completion;
-(void) getChannelsWithOptions : (NSArray *)tags inContext : (NSManagedObjectContext *) context withCompletion:(void (^)(NSArray *))completion;
-(void) getCategoriesForTags : (NSArray *)tags inContext : (NSManagedObjectContext *) context withCompletion:(void (^)(NSArray *))completion;

-(void) save;
-(void) clear;

@end

#endif /* HLTagManager_h */
