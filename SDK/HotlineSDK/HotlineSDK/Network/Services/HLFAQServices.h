//
//  HLFAQServices.h
//  
//
//  Created by Aravinth Chandran on 21/09/15.
//
//

#import <Foundation/Foundation.h>
#import "FDSecureStore.h"
#import "FDArticleContent.h"
#import "HLArticle.h"

/* 
 FAQServices fetches solutions and updates the database,
 users can observe key: HOTLINE_SOLUTIONS_UPDATED to get updates.
 */

@interface HLFAQServices : NSObject

-(NSURLSessionDataTask *)fetchAllCategories;
-(NSURLSessionDataTask *)vote:(BOOL)vote forArticleID:(NSNumber *)articleID inCategoryID:(NSNumber *)categoryID;

@end