//
//  HLListViewController.h
//  
//
//  Created by Aravinth Chandran on 23/09/15.
//
//

#import <UIKit/UIKit.h>
#import "FCMarginalView.h"
#import "FCJWTViewController.h"
#import "FAQOptionsInterface.h"

@interface FCListViewController : FCJWTViewController <UITableViewDelegate, UITableViewDataSource,UIGestureRecognizerDelegate,FDMarginalViewDelegate,FAQOptionsInterface>

@property(nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)FCMarginalView *footerView;

-(BOOL)canDisplayFooterView;

+ (float) heightOfCell: (UIFont *)font;

@end
