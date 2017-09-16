
//  FDPromptView.m
//  FreshdeskSDK
//
//  Created by AravinthChandran on 20/02/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FDPromptView.h"
#import "FCTheme.h"
#import "HLMacros.h"
#import "HLLocalization.h"

@implementation FDPromptView

-(UILabel *)createPromptLabel:(NSString *) key{
    UILabel *promptLabel = [[UILabel alloc] init];
    FCTheme *theme = [FCTheme sharedInstance];
    self.backgroundColor = [theme dialogueBackgroundColor];
    promptLabel.translatesAutoresizingMaskIntoConstraints = NO;
    promptLabel.textColor = [theme dialogueTitleTextColor];
    promptLabel.font = [theme dialogueTitleFont];
    promptLabel.lineBreakMode = NSLineBreakByWordWrapping;
    promptLabel.numberOfLines = 0;
    promptLabel.textAlignment= NSTextAlignmentCenter;
    promptLabel.text = HLLocalizedString([key stringByAppendingString:
                                               LOC_TEXT_PARTIAL]);
    return promptLabel;
}

-(UIButton *)createPromptButton:(NSString*)buttonName withKey:(NSString *)key{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    FCTheme *theme = [FCTheme sharedInstance];
    button.titleLabel.font = [theme dialogueTitleFont];
    button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    button.titleLabel.numberOfLines = 0;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    buttonName = [NSString stringWithFormat:LOC_BUTTON_TEXT_PARTIAL,buttonName];
    [button setTitle:HLLocalizedString([key stringByAppendingString:buttonName]) forState:UIControlStateNormal];
    
    [button setTitleColor:[theme dialogueNoButtonTextColor] forState:UIControlStateNormal];
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];
    return button;
}

-(UIButton *) createBorderedPromptButton:(NSString *)buttonKey withKey:(NSString *)promptKey {
    UIButton *button =[self createPromptButton:buttonKey withKey:promptKey];
    [[button layer] setBorderWidth:0.3f];
    button.layer.cornerRadius = 2;
    return button;
}

-(CGSize)sizeOfString:(NSString *)string withFont:(UIFont *)font{
    if (string) {
      return [string sizeWithAttributes:@{ NSFontAttributeName:font }];
    }else{
        return CGSizeMake(0, 0);
    }
}

-(void)layoutForPromptLabelInView:(UIView *)view{
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[promptLabel]-|" options:0 metrics:nil views:self.views]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[promptLabel]" options:0 metrics:nil views:self.views]];
}

-(CGFloat)getDesiredWidthFor:(UIButton *)button{
    CGFloat buttonLabelWidth = [self sizeOfString:button.titleLabel.text withFont:button.titleLabel.font].width;
    CGFloat desiredWidth = buttonLabelWidth + ADDITIONAL_OFFSET;
    return desiredWidth;
}

-(void)addSpacersInView:(UIView *)view{
    
    self.leftSpacer = [UIView new];
    self.leftSpacer.translatesAutoresizingMaskIntoConstraints = NO;
    self.rightSpacer = [UIView new];
    self.rightSpacer.translatesAutoresizingMaskIntoConstraints = NO;

    [view addSubview:self.leftSpacer];
    [view addSubview:self.rightSpacer];
}

-(void)addConstraintWithBaseLine:(NSString *)constraintString inView:(UIView *)view{
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:constraintString options:NSLayoutFormatAlignAllLastBaseline metrics:self.metrics views:self.views]];
}

-(void)addConstraint:(NSString *)constraintString InView:(UIView *)view{
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:constraintString options:0 metrics:self.metrics views:self.views]];
}

-(void)updateConstraints{
    [super updateConstraints];
}

-(void)clearPrompt{
    [self removeFromSuperview];
}

-(CGFloat)getPromptHeight{
    FDLog(@"Warning: unimplemented getPromptHeight Method");
    return 0;
}

@end
