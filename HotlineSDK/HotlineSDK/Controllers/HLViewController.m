//
//  HLViewController.m
//  HotlineSDK
//
//  Created by Hrishikesh on 05/02/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLViewController.h"
#import "HLTheme.h"
#import "HLMacros.h"
#import "FDBarButtonItem.h"
#import "HLControllerUtils.h"

@implementation HLViewController : UIViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (self.navigationController == nil) {
        ALog(@"Warning: Use Hotline controllers inside navigation controller");
    }
    else {
        self.navigationController.navigationBar.barStyle = [[HLTheme sharedInstance]statusBarStyle] == UIStatusBarStyleLightContent ?
                                                                    UIBarStyleBlack : UIBarStyleDefault; // barStyle has a different enum but same values .. so hack to clear the update.
        self.navigationController.navigationBar.tintColor = [[HLTheme sharedInstance] navigationBarButtonColor];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [HLControllerUtils configureGestureDelegate:[self gestureDelegate] forController:self withEmbedded:self.embedded];
}

-(UIViewController<UIGestureRecognizerDelegate> *) gestureDelegate {
    return nil;
}

-(void)configureBackButton{
    [HLControllerUtils configureBackButtonForController:self withEmbedded:self.embedded];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return [[HLTheme sharedInstance]statusBarStyle];
}

@end
