//
//  FDPromptView.m
//  FreshdeskSDK
//
//  Created by AravinthChandran on 20/02/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FDPromptView.h"
#import "FDTheme.h"

@implementation FDPromptView

-(instancetype)init{
    self = [super init];
    if (self) {
        FDTheme *theme = [FDTheme sharedInstance];
        self.backgroundColor = [theme dialogueBackgroundColor];
        self.promptLabel = [[UILabel alloc]init];
        self.promptLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.promptLabel.textColor = [theme dialogueTitleTextColor];
        self.promptLabel.font = [theme dialogueTitleFont];
        self.promptLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.promptLabel.numberOfLines = 0;
        self.promptLabel.textAlignment= NSTextAlignmentCenter;
        self.promptLabel.text = @"Default prompt label";
        [self addSubview:self.promptLabel];
    }
    return self;
}

-(void)layoutSubviews{
    NSDictionary *views = @{ @"promptLabel" : self.promptLabel };
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[promptLabel]-|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[promptLabel]" options:0 metrics:nil views:views]];
    [super layoutSubviews];
}

-(void)updateConstraints{
    [super updateConstraints];
}

-(void)clearPrompt{
    [self removeFromSuperview];
}

@end