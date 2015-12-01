//
//  HLListViewController.h
//  
//
//  Created by Aravinth Chandran on 23/09/15.
//
//

#import <UIKit/UIKit.h>
#import "FDMarginalView.h"

@interface HLListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,UIGestureRecognizerDelegate>

@property(nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)FDMarginalView *footerView;

-(BOOL)canDisplayFooterView;

@end
