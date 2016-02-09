//
//  HLContainerViewController.h
//  HotlineSDK
//
//  Created by AravinthChandran on 9/10/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HLContainerController : UIViewController

@property (nonatomic,strong)UIView *containerView;
@property (nonatomic, assign)BOOL isEmbeddable;

-(instancetype)initWithController:(UIViewController *)controller;

@end
