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
#import "HLArticle.h"
#import "HLChannel.h"

@interface HLTagManager : NSObject

+(instancetype)sharedInstance;

- (void) getChannelsForTags : (NSArray *)tags
                      inContext : (NSManagedObjectContext *) context
                  withCompletion:(void (^)(NSArray<HLChannel *> *))completion;

- (void) getCategoriesForTags : (NSArray *)tags
                    inContext : (NSManagedObjectContext *) context
                withCompletion:(void (^)(NSArray<HLCategory *> *))completion;

-(void)getArticlesForTags:(NSArray *)tags
              inContext:(NSManagedObjectContext *) context
          withCompletion :(void (^)(NSArray<HLArticle *> *))completion;

@end

#endif /* HLTagManager_h */
