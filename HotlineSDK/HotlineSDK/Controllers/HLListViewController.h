//
//  HLListViewController.h
//  
//
//  Created by Aravinth Chandran on 23/09/15.
//
//

#import <UIKit/UIKit.h>
#import "FDMarginalView.h"
#import "HLViewController.h"

@interface HLListViewController : HLViewController <UITableViewDelegate, UITableViewDataSource,UIGestureRecognizerDelegate,FDMarginalViewDelegate>

@property(nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)FDMarginalView *footerView;

-(BOOL)canDisplayFooterView;

+ (float) heightOfCell: (NSAttributedString *)textContent;

@end
