//
//  HLArticleTagManager.h
//  HotlineSDK
//
//  Created by Hrishikesh on 23/06/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#ifndef HLArticleTagManager_h
#define HLArticleTagManager_h

#import <Foundation/Foundation.h>

@interface HLArticleTagManager : NSObject

+(instancetype)sharedInstance;

-(void)addTag:(NSString *)tag forArticleId: (NSNumber *)articleId;
-(void)removeTagsForArticleId: (NSNumber *)articleId;
-(void) save;

@end

#endif /* HLArticleTagManager_h */
