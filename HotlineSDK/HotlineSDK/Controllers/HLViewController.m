//
//  HLViewController.m
//  HotlineSDK
//
//  Created by Hrishikesh on 05/02/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLViewController.h"

@implementation HLViewController : UIViewController

-(void)viewWillAppear:(BOOL)animated{
    if (self.navigationController == nil) {
        NSLog(@"Warning: Use Hotline controllers inside navigation controller");
    }
}

@end