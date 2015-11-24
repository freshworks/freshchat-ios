//
//  FDYesNoPromptView.m
//  FreshdeskSDK
//
//  Created by Arvchz on 23/02/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FDYesNoPromptView.h"
#import "HLMacros.h"
#import "HLTheme.h"

@interface FDYesNoPromptView ()

@property (nonatomic, strong) HLTheme *theme;
@property (strong, nonatomic) UILabel *promptLabel;
@property (nonatomic, strong) UIButton *YesButton;
@property (nonatomic, strong) UIButton *NoButton;
@property CGFloat button1DesiredWidth;
@property CGFloat button2DesiredWidth;

@end

@implementation FDYesNoPromptView

-(instancetype)initWithDelegate:(id<FDYesNoPromptViewDelegate>) delegate andKey:(NSString *)key{
    self = [super init];
    if (self) {
    self.theme = [HLTheme sharedInstance];
        
     self.promptLabel = [self createPromptLabel];
     self.promptLabel.text = HLLocalizedString([key stringByAppendingString:@" Label Text"]);
     [self addSubview:self.promptLabel];
        
     self.YesButton = [self createPromptButton:@"Yes" withKey:key];
     [self.YesButton setTitleColor:[self.theme dialogueYesButtonTextColor] forState:UIControlStateNormal];
     [self.YesButton setBackgroundColor:[self.theme dialogueYesButtonBackgroundColor]];
     [[self.YesButton layer] setBorderWidth:0.3f];
     
     self.YesButton.layer.cornerRadius = 2;
     [self.YesButton addTarget:self.delegate action:@selector(yesButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
     [self addSubview:self.YesButton];
        
     self.NoButton = [self createPromptButton:@"No" withKey:key];
     [self.NoButton setTitleColor:[self.theme dialogueNoButtonTextColor] forState:UIControlStateNormal];
     [self.NoButton setBackgroundColor:[self.theme dialogueNoButtonBackgroundColor]];
     [[self.NoButton layer] setBorderWidth:0.3f];
     self.NoButton.layer.cornerRadius = 2;
     [self.NoButton addTarget:self.delegate action:@selector(noButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
     [self addSubview:self.NoButton];
     [self addSpacersInView:self];
    }
    return self;
}

-(void)layoutSubviews{

    
    self.button1DesiredWidth = [self getDesiredWidthFor:self.YesButton];
    self.button2DesiredWidth = [self getDesiredWidthFor:self.NoButton];
    
    self.metrics = @{ @"desiredWidth1" : @(self.button1DesiredWidth),@"desiredWidth2" : @(self.button2DesiredWidth) , @"buttonSpacing" : @(BUTTON_SPACING) };
    self.views = @{@"Button1" : self.YesButton, @"Button2" : self.NoButton, @"promptLabel" : self.promptLabel, @"leftSpacer" : self.leftSpacer, @"rightSpacer" : self.rightSpacer, @"promptLabel" : self.promptLabel };
    
    //Constraints for label
    [self layoutForPromptLabelInView:self];
    
    
    //Constraints for buttons
    [self addConstraintWithBaseLine:@"H:|[leftSpacer][Button2(desiredWidth1)]-[Button1(desiredWidth2)][rightSpacer(leftSpacer)]|" inView:self];
    [self addConstraint:@"V:[promptLabel]-5-[Button1]" InView:self];
    [self addConstraint:@"V:[promptLabel]-5-[Button2]" InView:self];
    
    [super layoutSubviews];
}

@end