//
//  HLFAQServices.h
//  
//
//  Created by Aravinth Chandran on 21/09/15.
//
//

#import <Foundation/Foundation.h>
#import "FCSecureStore.h"
#import "FCArticleContent.h"
#import "FCArticles.h"

/* 
 FAQServices fetches solutions and updates the database,
 users can observe key: HOTLINE_SOLUTIONS_UPDATED to get updates.
 */

@interface FCFAQServices : NSObject

-(NSURLSessionDataTask *)fetchAllCategories:(void (^)(NSError *))completion;
-(NSURLSessionDataTask *)vote:(BOOL)vote forArticleID:(NSNumber *)articleID inCategoryID:(NSNumber *)categoryID;

@end
