//
//  FDCoreDataFetchManager.h
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 29/04/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>
#import "HLViewController.h"

@interface HLSearchViewController : HLViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSArray *searchResults;

@end