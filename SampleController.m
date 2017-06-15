//
//  SampleController.m
//  Hotline Demo
//
//  Created by user on 14/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "SampleController.h"
#import "HotlineSDK/Hotline.h"

@interface SampleController ()

@end

@implementation SampleController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loadChannels:(id)sender {
    [[Hotline sharedInstance] showConversations:self];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
