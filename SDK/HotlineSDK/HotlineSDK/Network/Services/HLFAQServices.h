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

@interface HLFAQServices : NSObject

@property (nonatomic, strong) FDSecureStore *secureStore;

-(NSURLSessionDataTask *)fetchAllCategories;
-(NSURLSessionDataTask *)fetchCategoriesInBatches;
-(NSArray *)fetchAllIndices;

@end
