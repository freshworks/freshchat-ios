//
//  ArticleTagManager.h
//  HotlineSDK
//
//  Created by Hrishikesh on 23/06/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#ifndef ArticleTagManager_h
#define ArticleTagManager_h

#import <Foundation/Foundation.h>

@interface ArticleTagManager : NSObject

+(instancetype)sharedInstance;

-(void)addTag:(NSString *)tag forArticleID: (NSNumber *)articleId;
-(void)removeTag:(NSString *)tag forArticleID: (NSNumber *)articleId;

@end

#endif /* ArticleTagManager_h */
