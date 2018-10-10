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
#import "FCAutolayoutHelper.h"

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
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [FCControllerUtils configureGestureDelegate:[self gestureDelegate] forController:self withEmbedded:self.embedded];
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
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

-(void) addJWTObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(jwtEventChange)
                                                 name:JWT_EVENT
                                               object:nil];
}

-(void) removeJWTObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:JWT_EVENT object:nil];
}

-(void) jwtEventChange {
    
}

- (enum JWT_UI_STATE) getUpdatedAction {
    return NO_CHANGE;
}

- (UIView *)contentDisplayView {
    return self.view;
}

- (NSString *)emptyText {
    return @"JWT ERROR";
}

- (NSString *)loadingText {
    return @"Waiting for JWT auth";
}

@end
