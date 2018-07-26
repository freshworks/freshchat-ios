//
//  FDPromptView.h
//  FreshdeskSDK
//
//  Created by AravinthChandran on 20/02/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

static const CGFloat ADDITIONAL_OFFSET = 120;
static const CGFloat BUTTON_SPACING = 30;
static CGFloat PROMPT_VIEW_HEIGHT  = 80;
static CGFloat ARTICLE_PROMPT_VIEW_HEIGHT = 84;
static CGFloat ALERT_PROMPT_VIEW_HEIGHT = 60;

@interface FCPromptView : UIView

-(void)clearPrompt;

@property (strong, nonatomic) UIView *leftSpacer;
@property (strong, nonatomic) UIView *rightSpacer;
@property (strong, nonatomic) NSDictionary *metrics;
@property (strong, nonatomic) NSDictionary *views;


-(UIButton *)createPromptButton:(NSString*)buttonName withKey:(NSString *)key;
-(UIButton *) createBorderedPromptButton:(NSString *)buttonKey withKey:(NSString *)promptKey;
-(UILabel *)createPromptLabel:(NSString *)key;

//Methods for layouts
-(void)addConstraintWithBaseLine:(NSString *)constraintString inView:(UIView *)view;
-(void)addConstraint:(NSString *)constraintString InView:(UIView *)view;
-(CGFloat)getDesiredWidthFor:(UIButton *)button;
-(void)layoutForPromptLabelInView:(UIView *)view;
-(void)addSpacersInView:(UIView *)view;

-(CGFloat)getPromptHeight;

@end
