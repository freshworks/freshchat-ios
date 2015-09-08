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

@class NSFetchedResultsController;
@class FDCoreDataFetchManager;

@protocol CoreDataFetchManagerDelegate
-(id)fetchManager:(FDCoreDataFetchManager *)manager cellForTableView:(UITableView *)tableView withObject:(id)object;

@optional

//If you are using a search based fetch controller
-(id)fetchManager:(FDCoreDataFetchManager *)manager cellForSearchTableView:(UITableView *)tableView withObject:(id)object;
-(NSFetchRequest *)fetchRequestForSearchTerm:(NSString *)term;

@end

@interface FDCoreDataFetchManager : NSObject <UITableViewDataSource, NSFetchedResultsControllerDelegate, UITableViewDelegate>
//Properties
@property (nonatomic, weak  ) id<CoreDataFetchManagerDelegate> delegate;
@property (nonatomic, strong) NSFetchedResultsController   *fetchedResultsController;
@property (nonatomic        ) BOOL                         paused;
@property (strong, nonatomic) NSArray               *searchResults;

//Public API
- (void) performFetch;
- (instancetype)initWithTableView:(UITableView *)tableView withRowAnimation:(UITableViewRowAnimation)animation;
- (instancetype)initWithSearchBar:(UISearchBar *)searchBar withContentsController:(id)controller andTableView:(UITableView *)tableView;
@end