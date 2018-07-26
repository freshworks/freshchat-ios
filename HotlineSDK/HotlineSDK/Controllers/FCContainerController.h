//
//  HLContainerViewController.h
//  HotlineSDK
//
//  Created by AravinthChandran on 9/10/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FCViewController.h"
#import "FCFooterView.h"

#define FRESHCHAT_ACCOUNT_DELETED_EVENT @"com.freshworks.freshchat_account_deleted_event"

@interface FCContainerController : UIViewController

@property (nonatomic,strong)UIView *containerView;
@property (nonatomic, strong) FCViewController *childController;
@property (nonatomic, strong) FCFooterView  *footerView;

- (instancetype)initWithController:(FCViewController *)controller andEmbed:(BOOL) embed;

@end
