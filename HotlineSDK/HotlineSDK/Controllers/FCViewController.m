//
//  HLViewController.m
//  HotlineSDK
//
//  Created by Hrishikesh on 05/02/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCViewController.h"
#import "FCTheme.h"
#import "FCMacros.h"
#import "FCBarButtonItem.h"
#import "FCControllerUtils.h"
#import "JWTAuthValidator.h"

@implementation FCViewController : UIViewController

-(void) viewDidLoad {
    [super viewDidLoad];    
}

-(void) viewDidUnload {
    [super viewDidUnload];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (self.navigationController == nil) {
        ALog(@"Warning: Use Hotline controllers inside navigation controller");
    }
    else {
        self.navigationController.navigationBar.barStyle = [[FCTheme sharedInstance]statusBarStyle] == UIStatusBarStyleLightContent ?
                                                                    UIBarStyleBlack : UIBarStyleDefault; // barStyle has a different enum but same values .. so hack to clear the update.
        self.navigationController.navigationBar.tintColor = [[FCTheme sharedInstance] navigationBarButtonColor];
    }
    [self addJWTObserevers];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [FCControllerUtils configureGestureDelegate:[self gestureDelegate] forController:self withEmbedded:self.embedded];
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self removeJWTObserevers];
}

-(UIViewController<UIGestureRecognizerDelegate> *) gestureDelegate {
    return nil;
}

-(void)configureBackButton{
    [FCControllerUtils configureBackButtonForController:self withEmbedded:self.embedded];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return [[FCTheme sharedInstance]statusBarStyle];
}

-(void) addJWTObserevers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(jwtActive)
                                                 name:ACTIVE_EVENT
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(waitForFirstToken)
                                                 name:WAIT_FOR_FIRST_TOKEN_EVENT
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(verificationUnderProgress)
                                                 name:VERIFICATION_UNDER_PROGRESS_EVENT
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(waitingForRefreshToken)
                                                 name:WAITING_FOR_REFRESH_TOKEN_EVENT
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tokenVerificationFailed)
                                                 name:TOKEN_VERIFICATION_FAILED_EVENT
                                               object:nil];
}

-(void) removeJWTObserevers {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ACTIVE_EVENT object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:WAIT_FOR_FIRST_TOKEN_EVENT object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VERIFICATION_UNDER_PROGRESS_EVENT object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:WAITING_FOR_REFRESH_TOKEN_EVENT object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TOKEN_VERIFICATION_FAILED_EVENT object:nil];
}

-(void)jwtActive {
    [self resetViews];
}

-(void)waitForFirstToken {
    [self resetViews];
    [self showLoadingScreen];
}

-(void)verificationUnderProgress {
    [self resetViews];
}

-(void)waitingForRefreshToken {
    [self resetViews];
}

-(void)tokenVerificationFailed {
    [self resetViews];
}

-(void) resetViews {
    [self removeLoadingScreen];
}

-(void) showLoadingScreen {
    self.loadingVC = [[UIView alloc]init];
    self.loadingVC.frame = CGRectMake(-20, -20, self.view.frame.size.width, self.view.frame.size.height);
    self.loadingVC.translatesAutoresizingMaskIntoConstraints = NO;
    self.loadingVC.backgroundColor = UIColor.whiteColor;
    self.loadingVC.alpha = 0.6;
    [self.view addSubview:self.loadingVC];
    self.viewsVC = @{ @"loadingVC" : self.loadingVC};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[loadingVC]-0-|" options:0 metrics:nil views:self.viewsVC]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[loadingVC]-0-|" options:0 metrics:nil views:self.viewsVC]];
    [self.view bringSubviewToFront:self.loadingVC];
}

-(void) removeLoadingScreen {
    [self.loadingVC removeFromSuperview];
    self.viewsVC = @{};
}

@end
