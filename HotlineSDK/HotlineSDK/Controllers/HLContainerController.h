//
//  HLContainerViewController.h
//  HotlineSDK
//
//  Created by AravinthChandran on 9/10/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HLViewController.h"


@interface HLContainerController : UIViewController

@property (nonatomic,strong)UIView *containerView;

-(instancetype)initWithController:(HLViewController *)controller andEmbed:(BOOL) embed;

@end
