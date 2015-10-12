//
//  HLFAQServices.h
//  
//
//  Created by Aravinth Chandran on 21/09/15.
//
//

#import <Foundation/Foundation.h>

@interface HLFAQServices : NSObject

-(NSURLSessionDataTask *)fetchAllCategories;
-(NSURLSessionDataTask *)fetchCategoriesInBatches;

@end
