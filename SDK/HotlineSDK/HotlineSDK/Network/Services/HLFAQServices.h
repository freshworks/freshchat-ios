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
-(NSURLSessionDataTask *)upVoteFor:(NSNumber *)articleID inCategory:(NSNumber *)categoryID;
-(NSURLSessionDataTask *)downVoteFor:(NSNumber *)articleID inCategory:(NSNumber *)categoryID;

@end