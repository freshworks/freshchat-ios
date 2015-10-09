//
//  FDPromptView.h
//  FreshdeskSDK
//
//  Created by AravinthChandran on 20/02/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

static const CGFloat ADDITIONAL_OFFSET = 25;
static const CGFloat BUTTON_SPACING = 30;
static CGFloat PROMPT_VIEW_HEIGHT  = 80;

@interface FDPromptView : UIView

-(void)clearPrompt;

@property (strong, nonatomic) UIView *leftSpacer;
@property (strong, nonatomic) UIView *rightSpacer;
@property (strong, nonatomic) NSDictionary *metrics;
@property (strong, nonatomic) NSDictionary *views;


-(UIButton *)createPromptButton:(NSString*)buttonName withKey:(NSString *)key;
-(UILabel *)createPromptLabel;

//Methods for layouts
-(void)addConstraintWithBaseLine:(NSString *)constraintString inView:(UIView *)view;
-(void)addConstraint:(NSString *)constraintString InView:(UIView *)view;
-(CGFloat)getDesiredWidthFor:(UIButton *)button;
-(void)layoutForPromptLabelInView:(UIView *)view;
-(void)addSpacersInView:(UIView *)view;

@end