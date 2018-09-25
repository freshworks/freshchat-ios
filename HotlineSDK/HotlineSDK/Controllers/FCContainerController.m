//
//  HLContainerViewController.m
//  HotlineSDK
//
//  Created by AravinthChandran on 9/10/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FCContainerController.h"
#import "FCTheme.h"
#import "HotlineAppState.h"
#import "FCUtilities.h"
#import "FCAutolayoutHelper.h"

@interface FCContainerController ()

@property (strong, nonatomic) FCTheme *theme;

@end

@interface Freshchat ()

-(void)dismissEmbededFreshchatViews;

@end

@implementation FCContainerController

-(instancetype)initWithController:(FCViewController *)controller andEmbed:(BOOL) embed{
    self = [super init];
    if (self) {
        self.childController = controller;
        self.childController.embedded = embed;
        self.theme = [FCTheme sharedInstance];
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
    BOOL isembedView = (self.tabBarController != nil) ? TRUE : FALSE;
    self.footerView = [[FCFooterView alloc] initFooterViewWithEmbedded:isembedView];
    self.footerView.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:self.footerView];
    NSDictionary *views = @{ @"containerView" : self.containerView, @"footerView" : self.footerView, @"childControllerView" : self.childController.view};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[containerView]|" options:0 metrics:nil views:views]];
    if([FCUtilities isPoweredByFooterViewHidden] &&(![FCUtilities hasNotchDisplay] || isembedView)){
        [self.footerView removeFromSuperview];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[containerView]|" options:0 metrics:nil views:views]];
    }
    else{
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[footerView]|" options:0 metrics:nil views:views]];
        int footerViewHeight = 20;
        if([FCUtilities hasNotchDisplay] && !isembedView) {
            footerViewHeight = 33;
        }
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|[containerView][footerView(%d)]|", footerViewHeight] options:0 metrics:nil views:views]];
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

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [HotlineAppState sharedInstance].currentVisibleController = self.childController;
    if([FCUtilities isAccountDeleted]) {
        [self handleAccountDeletedState];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccountDeletedState)
                                                 name:FRESHCHAT_ACCOUNT_DELETED_EVENT object:nil];
}
- (void) handleAccountDeletedState{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[Freshchat sharedInstance] dismissEmbededFreshchatViews];
    });
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [HotlineAppState sharedInstance].currentVisibleController = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:FRESHCHAT_ACCOUNT_DELETED_EVENT];
}

@end
