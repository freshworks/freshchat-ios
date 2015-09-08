//
//  FDClosedPromptView.m
//  FreshdeskSDK
//
//  Created by Arvchz on 23/02/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FDClosedPromptView.h"
#import "FDBorderedButton.h"
#import "FDMacros.h"
#import "FDKit.h"
#import "FDTheme.h"

@interface FDClosedPromptView ()

@property (weak, nonatomic) id <FDClosedPromptViewDelegate> closedPromptViewDelegate;

@end

@implementation FDClosedPromptView

-(instancetype)initWithDelegate:(id<FDClosedPromptViewDelegate>)delegate{
    self = [super init];

    if (self) {
        
        self.closedPromptViewDelegate = delegate;
        
        FDTheme *theme = [FDTheme sharedInstance];
        
        self.promptLabel.text = FDLocalizedString(@"conversation ended");
        
        FDButton *button = [FDButton buttonWithType:UIButtonTypeSystem];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        button.titleLabel.font = [theme dialogueButtonFont];
        [button setTitleColor:[theme dialogueButtonTextColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(startNewConversationClicked:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:FDLocalizedString(@"Start a new conversation") forState:UIControlStateNormal];
        [self addSubview:button];
        
        NSLayoutConstraint *buttonCenterX = [NSLayoutConstraint constraintWithItem:button
                                                                         attribute:NSLayoutAttributeCenterX
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self
                                                                         attribute:NSLayoutAttributeCenterX
                                                                        multiplier:1.0 constant:0];
        
        NSDictionary *viewDictionary = @{ @"promptLabel" : self.promptLabel, @"startNewConversationButton" : button };
        [self addConstraints:@[buttonCenterX]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[promptLabel]-10-[startNewConversationButton]" options:0 metrics:nil views:viewDictionary]];
    }
    return self;
}

-(void)startNewConversationClicked:(id)sender{
    [self.closedPromptViewDelegate closedPromptOnStartingNewConversation];
}

@end