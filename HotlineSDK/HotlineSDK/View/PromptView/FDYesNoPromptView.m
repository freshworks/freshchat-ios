//
//  FDYesNoPromptView.m
//  FreshdeskSDK
//
//  Created by Arvchz on 23/02/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FDYesNoPromptView.h"
#import "HLMacros.h"
#import "HLLocalization.h"

@interface FDYesNoPromptView ()

@end

@implementation FDYesNoPromptView

-(instancetype)initWithDelegate:(id<HLYesNoPromptViewDelegate>) delegate andKey:(NSString *)key{
    self = [super init];
    if (self) {
        self.theme = [FCTheme sharedInstance];

        self.promptLabel = [self createPromptLabel:key];
        [self addSubview:self.promptLabel];

        self.YesButton = [self createBorderedPromptButton:@"yes" withKey:key];
        [self.YesButton setTitleColor:[self.theme dialogueYesButtonTextColor] forState:UIControlStateNormal];
        [self.YesButton setBackgroundColor:[self.theme dialogueYesButtonBackgroundColor]];
        [self.YesButton.titleLabel setFont:[self.theme dialogueYesButtonFont]];
        self.YesButton.layer.borderColor = [[self.theme dialogueYesButtonBorderColor] CGColor];

        [self.YesButton addTarget:self.delegate action:@selector(yesButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.YesButton];

        self.NoButton = [self createBorderedPromptButton:@"no" withKey:key];
        [self.NoButton setTitleColor:[self.theme dialogueNoButtonTextColor] forState:UIControlStateNormal];
        [self.NoButton setBackgroundColor:[self.theme dialogueNoButtonBackgroundColor]];
        [self.NoButton.titleLabel setFont:[self.theme dialogueNoButtonFont]];
        self.NoButton.layer.borderColor = [[self.theme dialogueNoButtonBorderColor] CGColor];

        [self.NoButton addTarget:self.delegate action:@selector(noButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.NoButton];

        [self addSpacersInView:self];
    }
    return self;
}

-(void)layoutSubviews{

    CGFloat button1DesiredWidth = [self getDesiredWidthFor:self.YesButton];
    CGFloat button2DesiredWidth = [self getDesiredWidthFor:self.NoButton];
    
    self.metrics = @{ @"desiredWidth1" : @(button1DesiredWidth),@"desiredWidth2" : @(button2DesiredWidth) , @"buttonSpacing" : @(BUTTON_SPACING) };
    self.views = @{@"Button1" : self.YesButton, @"Button2" : self.NoButton, @"promptLabel" : self.promptLabel, @"leftSpacer" : self.leftSpacer, @"rightSpacer" : self.rightSpacer };
    
    //Constraints for label
    [self layoutForPromptLabelInView:self];
    
    //Constraints for buttons

    [self addConstraintWithBaseLine:@"H:|[leftSpacer][Button2(desiredWidth1)]-15-[Button1(desiredWidth2)][rightSpacer(leftSpacer)]|" inView:self];

    [self addConstraint:@"V:[promptLabel]-16-[Button1]" InView:self];
    [self addConstraint:@"V:[promptLabel]-16-[Button2]" InView:self];
    
    [super layoutSubviews];
}

-(CGFloat)getPromptHeight{
    return ARTICLE_PROMPT_VIEW_HEIGHT;
}

@end
