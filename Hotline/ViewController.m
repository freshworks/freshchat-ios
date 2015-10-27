//
//  ViewController.m
//  Hotline
//
//  Created by AravinthChandran on 9/7/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "ViewController.h"
#import "HotlineSDK/Hotline.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)showFAQ:(id)sender {
    [Hotline presentSolutions:self];
}

- (IBAction)conversations:(id)sender {
    [Hotline presentFeedback:self];
}

- (IBAction)settings:(id)sender {
    NSLog(@"Settings");
}

@end