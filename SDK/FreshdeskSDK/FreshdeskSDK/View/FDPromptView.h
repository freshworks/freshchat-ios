//
//  FDPromptView.h
//  FreshdeskSDK
//
//  Created by AravinthChandran on 20/02/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface FDPromptView : UIView

@property (strong, nonatomic) UILabel          *promptLabel;

-(void)clearPrompt;

@end