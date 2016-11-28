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
#import "FDBarButtonItem.h"

@implementation HLViewController : UIViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (self.navigationController == nil) {
        NSLog(@"Warning: Use Hotline controllers inside navigation controller");
    }
    else {
        self.navigationController.navigationBar.barStyle = [[HLTheme sharedInstance]statusBarStyle] == UIStatusBarStyleLightContent ?
                                                                    UIBarStyleBlack : UIBarStyleDefault; // barStyle has a different enum but same values .. so hack to clear the update.
        self.navigationController.navigationBar.tintColor = [[HLTheme sharedInstance] navigationBarButtonColor];
    }
}

-(void)configureBackButtonWithGestureDelegate:(UIViewController <UIGestureRecognizerDelegate> *)gestureDelegate{
    BOOL isBackButtonImageExist = [[HLTheme sharedInstance]getImageWithKey:IMAGE_BACK_BUTTON] ? YES : NO;
    UINavigationController *naviController = nil;
    if (isBackButtonImageExist && ![self embedded]) {
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[[HLTheme sharedInstance] getImageWithKey:IMAGE_BACK_BUTTON]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self.navigationController
                                                                      action:@selector(popViewControllerAnimated:)];
        self.parentViewController.navigationItem.leftBarButtonItem = backButton;
        if([self conformsToProtocol:@protocol(UIGestureRecognizerDelegate)]){
            naviController = self.navigationController;
            if(gestureDelegate){
                naviController = (self.parentViewController) ? self.parentViewController.navigationController : naviController;
                [naviController.interactivePopGestureRecognizer setEnabled:YES];
                naviController.interactivePopGestureRecognizer.delegate = gestureDelegate;
            }else{
                [naviController.interactivePopGestureRecognizer setEnabled:NO];
            }
        }
    }else{
        naviController = self.parentViewController.navigationController;
        self.parentViewController.navigationItem.backBarButtonItem = [[FDBarButtonItem alloc] initWithTitle:@""
                                                                                                      style:self.parentViewController.navigationItem.backBarButtonItem.style
                                                                                                     target:nil action:nil];
        [naviController.interactivePopGestureRecognizer setEnabled:NO];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return [[HLTheme sharedInstance]statusBarStyle];
}

@end
