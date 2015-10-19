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

@interface HLSearchViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
//Properties
@property (strong, nonatomic) NSArray               *searchResults;

//Public API
- (instancetype)initWithTableView:(UITableView *)tableView withRowAnimation:(UITableViewRowAnimation)animation;
- (instancetype)initWithSearchBar:(UISearchBar *)searchBar withContentsController:(id)controller andTableView:(UITableView *)tableView;
@end