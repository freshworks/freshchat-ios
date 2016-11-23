//
//  HLCategoriesListController.h
//  
//
//  Created by Aravinth Chandran on 23/09/15.
//
//

#import <UIKit/UIKit.h>
#import "HLListViewController.h"
#import "FAQOptionsInterface.h"

@interface HLCategoryListController : HLListViewController<FAQOptionsInterface>

@property (nonatomic, strong) NSArray *tagsArray;
@property (nonatomic, assign) NSString *tagsTitle;

@end
