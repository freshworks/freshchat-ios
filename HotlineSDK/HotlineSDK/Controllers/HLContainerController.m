//
//  HLContainerViewController.m
//  HotlineSDK
//
//  Created by AravinthChandran on 9/10/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "HLContainerController.h"
#import "HLTheme.h"
#import "HotlineAppState.h"
#import "FDUtilities.h"
#import "FDAutolayoutHelper.h"
#import "FCRemoteConfigUtil.h"

@interface HLContainerController ()

@property (strong, nonatomic) HLTheme *theme;

@end

@implementation HLContainerController

-(instancetype)initWithController:(HLViewController *)controller andEmbed:(BOOL) embed{
    self = [super init];
    if (self) {
        self.childController = controller;
        self.childController.embedded = embed;
        self.theme = [HLTheme sharedInstance];
    }
    return self;
}

-(UIRectEdge)edgesForExtendedLayout{
    return UIRectEdgeNone;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setNavigationBarConfig];

    self.containerView = [UIView new];
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.containerView];
    
    UIView *footerView = [UIView new];
    footerView.translatesAutoresizingMaskIntoConstraints = NO;
    footerView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:footerView];
    
    //#imclude both changes server check and internal md5 check also :)
    BOOL isPoweredByHidden = [FDUtilities isPoweredByHidden];
    BOOL isSubscribed = [FCRemoteConfigUtil isSubscribedUser];
    
    //Footerview label
    UILabel *footerLabel = [UILabel new];
    footerLabel.text = @"Powered by hotline.io";
    footerLabel.font = [UIFont systemFontOfSize:11];
    footerLabel.textColor = [UIColor whiteColor];
    footerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [footerView addSubview:footerLabel];
    [FDAutolayoutHelper center:footerLabel onView:footerView];
    
    NSDictionary *views = @{ @"containerView" : self.containerView, @"footerView" : footerView, @"childControllerView" : self.childController.view};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[containerView]|" options:0 metrics:nil views:views]];
    if(isSubscribed && isPoweredByHidden){
        [footerView removeFromSuperview];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[containerView]|" options:0 metrics:nil views:views]];
    }
    else{
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[footerView]|" options:0 metrics:nil views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[containerView][footerView(20)]|" options:0 metrics:nil views:views]];
    }
    
    self.childController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.childController.view];
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[childControllerView]|" options:0 metrics:nil views:views]];
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[childControllerView]|" options:0 metrics:nil views:views]];
    
    // This invokes the child controllers -willMoveToParentViewController:
    [self addChildViewController:self.childController];
}

-(void)setNavigationBarConfig{
    
    /*
     
     Made navigation bar to be opaque
     
     This will fix the view from being framed underneath the navigation bar and status bar.
     http://stackoverflow.com/questions/18798792
     
     All setting to the navigation bar has to refer parent view controller since we are using
     container controller
     
     */
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.barTintColor = [self.theme navigationBarBackgroundColor];
    [self.navigationController.navigationBar setTitleTextAttributes:@{
                                                                      NSForegroundColorAttributeName: [self.theme navigationBarTitleColor],
                                                                      NSFontAttributeName: [self.theme navigationBarTitleFont]
                                                                      }];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [HotlineAppState sharedInstance].currentVisibleController = self.childController;
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [HotlineAppState sharedInstance].currentVisibleController = nil;
}

@end
