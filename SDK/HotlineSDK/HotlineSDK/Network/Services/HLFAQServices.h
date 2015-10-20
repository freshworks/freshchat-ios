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

@interface HLFAQServices : NSObject

@property (nonatomic, strong) FDSecureStore *secureStore;

-(NSURLSessionDataTask *)fetchAllCategories;
-(NSURLSessionDataTask *)fetchCategoriesInBatches;
-(NSArray *)fetchAllIndices;
-(NSURLSessionDataTask *)vote:(BOOL)vote forArticleID:(NSNumber *)articleID inCategoryID:(NSNumber *)categoryID;

@end