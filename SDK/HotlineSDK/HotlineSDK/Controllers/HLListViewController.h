//
//  HLListViewController.h
//  
//
//  Created by Aravinth Chandran on 23/09/15.
//
//

#import <UIKit/UIKit.h>

@interface HLListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong)UITableView *tableView;

@end
