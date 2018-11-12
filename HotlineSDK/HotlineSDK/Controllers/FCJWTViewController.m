//
//  HLViewController.m
//  HotlineSDK
//
//  Created by Hrishikesh on 05/02/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCJWTViewController.h"
#import "FCJWTAuthValidator.h"
#import "FCJWTUtilities.h"
#import "FCRemoteConfig.h"

@implementation FCJWTViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return [[FCTheme sharedInstance]statusBarStyle];
}

-(void) addJWTObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(jwtStateChange)
                                                 name:JWT_EVENT
                                               object:nil];
}

-(void) removeJWTObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:JWT_EVENT object:nil];
}

-(void)jwtStateChange {
    dispatch_async(dispatch_get_main_queue(), ^{ /* show alert view */
        switch ([[FCJWTAuthValidator sharedInstance] getUiActionForTransition]) {
            case LOADING:
                [self showJWTLoading];
                break;
            case SHOW_ALERT:
                [self showJWTVerificationFailedAlert];
                break;
            case SHOW_CONTENT_WITH_TIMER :
                [self hideJWTLoading];
                [[FCJWTAuthValidator sharedInstance] startExpiryTimer];
                break;
            default:
                [self hideJWTLoading];
                break;
        };
    });
}

@end
