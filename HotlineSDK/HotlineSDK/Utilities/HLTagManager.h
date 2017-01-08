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

-(void) getArticlesForTags : (NSArray *)tags inContext :(NSManagedObjectContext *)context withCompletion:(void (^)(NSArray *))completion;
-(void) getChannelsWithOptions : (NSArray *)tags inContext : (NSManagedObjectContext *) context withCompletion:(void (^)(NSArray *))completion;
-(void) getCategoriesForTags : (NSArray *)tags inContext : (NSManagedObjectContext *) context withCompletion:(void (^)(NSArray *))completion;

@end

#endif /* HLTagManager_h */
