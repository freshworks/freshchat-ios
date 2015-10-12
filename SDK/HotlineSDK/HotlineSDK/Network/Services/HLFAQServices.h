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

-(NSURLSessionDataTask *)upVoteFor:(NSNumber *)articleID inCategory:(NSNumber *)categoryID;
-(NSURLSessionDataTask *)downVoteFor:(NSNumber *)articleID inCategory:(NSNumber *)categoryID;

-(NSURLSessionDataTask *)fetchAllCategories;
-(NSURLSessionDataTask *)fetchCategoriesInBatches;


@end
