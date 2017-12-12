//
//  HLContainerViewController.h
//  HotlineSDK
//
//  Created by AravinthChandran on 9/10/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HLViewController.h"
#import "FCFooterView.h"

@interface HLContainerController : UIViewController

@property (nonatomic,strong)UIView *containerView;
@property (nonatomic, strong) HLViewController *childController;
@property (nonatomic, strong) FCFooterView  *footerView;

- (instancetype)initWithController:(HLViewController *)controller andEmbed:(BOOL) embed;

@end
