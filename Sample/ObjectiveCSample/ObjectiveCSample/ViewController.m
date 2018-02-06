//
//  ViewController.m
//  ObjectiveCSample
//
//  Created by user on 18/09/17.
//  Copyright © 2017 Sanjith J K. All rights reserved.
//

#import "ViewController.h"
#import "FreshchatSDK/FreshchatSDK.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showFAQs:(id)sender {
    [[Freshchat sharedInstance] showFAQs:self];
}

- (IBAction)showConversations:(id)sender {
    [[Freshchat sharedInstance] showConversations:self];
}


@end
