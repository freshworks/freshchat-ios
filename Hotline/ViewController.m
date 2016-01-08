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

@property (weak, nonatomic) IBOutlet UIButton *chatButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    self.view.backgroundColor = [UIColor colorWithHue:0 saturation:0 brightness:0.95 alpha:1];
    [super viewDidLoad];
}

- (IBAction)showFAQ:(id)sender {
    [[Hotline sharedInstance] presentSolutions:self];
}

- (IBAction)settings:(id)sender {
    FDSettingsController *settings = [FDSettingsController new];
    UINavigationController *navigationController = [[UINavigationController alloc]init];
    navigationController.viewControllers = @[settings];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (IBAction)chatButtonPressed:(id)sender {
    [[Hotline sharedInstance]presentFeedback:self];
}

@end