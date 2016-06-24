//
//  HLArticlesViewController.h
//  HotlineSDK
//
//  Created by AravinthChandran on 9/9/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HLCategory.h"
#import "HLListViewController.h"
#import "FAQOptionsInterface.h"

@interface HLArticlesController : HLListViewController<FAQOptionsInterface>

-(instancetype)initWithCategory:(HLCategory *)category;

@end
