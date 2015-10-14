//
//  HLFAQServices.h
//  
//
//  Created by Aravinth Chandran on 21/09/15.
//
//

#import <Foundation/Foundation.h>
#import "HLArticle.h"

@interface HLFAQServices : NSObject

-(NSURLSessionDataTask *)fetchAllCategories;
-(NSURLSessionDataTask *)fetchCategoriesInBatches;
-(NSURLSessionDataTask *)vote:(BOOL)vote forArticleID:(NSNumber *)articleID inCategoryID:(NSNumber *)categoryID;

@end