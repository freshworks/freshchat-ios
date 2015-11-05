//
//  ViewController.m
//  Hotline
//
//  Created by AravinthChandran on 9/7/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "ViewController.h"
#import "HotlineSDK/Hotline.h"
#import "FDSettingsController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)showFAQ:(id)sender {
    [[Hotline sharedInstance] presentSolutions:self];
}

- (IBAction)conversations:(id)sender {
    [Hotline showFeedbackScreen];

}

- (IBAction)settings:(id)sender {
    FDSettingsController *settings = [FDSettingsController new];
    UINavigationController *navigationController = [[UINavigationController alloc]init];
    navigationController.viewControllers = @[settings];
    [self presentViewController:navigationController animated:YES completion:nil];
}

@end
