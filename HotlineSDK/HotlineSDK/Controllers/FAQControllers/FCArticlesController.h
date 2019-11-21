//
//  HLArticlesViewController.h
//  HotlineSDK
//
//  Created by AravinthChandran on 9/9/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FCCategories.h"
#import "FCListViewController.h"
#import "FAQOptionsInterface.h"

@interface FCArticlesController : FCListViewController<FAQOptionsInterface>

-(instancetype)initWithCategory:(FCCategories *)category;
@property BOOL isFallback;

@end
