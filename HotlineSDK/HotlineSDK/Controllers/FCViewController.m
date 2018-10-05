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
    [self addJWTObserevers];
}

-(void) viewDidUnload {
    [super viewDidUnload];
    [self removeJWTObserevers];
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
    
}

-(void)waitForFirstToken {
    
}

-(void)verificationUnderProgress {
    
}

-(void)waitingForRefreshToken {
    
}

-(void)tokenVerificationFailed {
    
}

@end
