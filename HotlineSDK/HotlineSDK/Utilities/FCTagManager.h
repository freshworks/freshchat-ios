//
//  HLTagManager.h
//  HotlineSDK
//
//  Created by Hrishikesh on 23/06/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#ifndef HLTagManager_h
#define HLTagManager_h

#import "FCDataManager.h"
#import <Foundation/Foundation.h>
#import "FCArticles.h"
#import "FCChannels.h"

@interface FCTagManager : NSObject

+(instancetype)sharedInstance;

- (void) getChannelsForTags : (NSArray *)tags
                      inContext : (NSManagedObjectContext *) context
                  withCompletion:(void (^)(NSArray<FCChannels *> *, NSError *))completion;

- (void) getCategoriesForTags : (NSArray *)tags
                    inContext : (NSManagedObjectContext *) context
                withCompletion:(void (^)(NSArray<FCCategories *> *))completion;

-(void)getArticlesForTags:(NSArray *)tags
              inContext:(NSManagedObjectContext *) context
          withCompletion :(void (^)(NSArray<FCArticles *> *))completion;


-(void)deleteTagWithTaggableType: (NSArray *)tagTypes
                 handler:(void(^)(NSError *error))handler
               inContext:(NSManagedObjectContext *) context;

- (void) getChannel: (NSArray *)tags
        channelIds : (NSArray *) channelIds
         inContext : (NSManagedObjectContext *) context
     withCompletion:(void (^)(NSArray<FCChannels *> *, NSError *))completion;

@end

#endif /* HLTagManager_h */
