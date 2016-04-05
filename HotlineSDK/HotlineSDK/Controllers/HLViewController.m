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
    if (self.navigationController == nil) {
        NSLog(@"Warning: Use Hotline controllers inside navigation controller");
    }
    else {
        self.navigationController.navigationBar.barStyle = [[HLTheme sharedInstance]statusBarStyle];
    }
}

-(void)configureBackButton{
    BOOL isBackButtonImageExist = [[HLTheme sharedInstance]getImageWithKey:IMAGE_BACK_BUTTON];
    
    if (!isBackButtonImageExist) {
        self.navigationController.navigationBar.tintColor = [[HLTheme sharedInstance] navigationBarButtonColor];
        self.parentViewController.navigationItem.backBarButtonItem = [[FDBarButtonItem alloc] initWithTitle:@""
                                                                                                      style:self.parentViewController.navigationItem.backBarButtonItem.style
                                                                                                     target:nil action:nil];
    }
}

@end