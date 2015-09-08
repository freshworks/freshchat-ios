//
//  FDResolvedPromptView.m
//  FreshdeskSDK
//
//  Created by Arvchz on 23/02/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FDResolvedPromptView.h"
#import "FDBorderedButton.h"
#import "FDMacros.h"
#import "FDKit.h"
#import "FDTheme.h"

@interface FDResolvedPromptView ()

@property (weak, nonatomic) id <FDResolvedPromptViewDelegate> resolvedPromptViewDelegate;
@property (nonatomic, strong) FDButton *ticketResolvedButton;
@property (nonatomic, strong) FDButton *ticketNotResolvedButton;

@end

@implementation FDResolvedPromptView

static const CGFloat ADDITIONAL_OFFSET = 25;
static const CGFloat BUTTON_SPACING = 30;

-(instancetype)initWithDelegate:(id<FDResolvedPromptViewDelegate>)delegate{
    self = [super init];
    if (self) {
        
        self.resolvedPromptViewDelegate = delegate;
        
        self.promptLabel.text = FDLocalizedString(@"Did we help solve your issue");
        FDTheme *theme = [FDTheme sharedInstance];
        
        self.ticketResolvedButton = [FDButton buttonWithType:UIButtonTypeSystem];
        self.ticketResolvedButton.titleLabel.font = [theme dialogueButtonFont];
        [self.ticketResolvedButton addTarget:self action:@selector(ticketResolvedButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        self.ticketResolvedButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.ticketResolvedButton setTitle:FDLocalizedString(@"YES") forState:UIControlStateNormal];
        [self.ticketResolvedButton setTitleColor:[theme dialogueButtonTextColor] forState:UIControlStateNormal];
        [self addSubview:self.ticketResolvedButton];

        self.ticketNotResolvedButton = [FDButton buttonWithType:UIButtonTypeSystem];
        self.ticketNotResolvedButton.titleLabel.font = [theme dialogueButtonFont];
        [self.ticketNotResolvedButton addTarget:self action:@selector(ticketNotResolvedButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        self.ticketNotResolvedButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.ticketNotResolvedButton setTitle:FDLocalizedString(@"NO") forState:UIControlStateNormal];
        [self.ticketNotResolvedButton setTitleColor:[theme dialogueButtonTextColor] forState:UIControlStateNormal];
        [self addSubview:self.ticketNotResolvedButton];
        
    }
    return self;
}

-(void)layoutSubviews{
    
    CGFloat ticketNotResolvedButtonLabelWidth = [self sizeOfString:self.ticketNotResolvedButton.titleLabel.text withFont:self.ticketNotResolvedButton.titleLabel.font].width;
    CGFloat ticketResolvedButtonLabelWidth = [self sizeOfString:self.ticketResolvedButton.titleLabel.text withFont:self.ticketResolvedButton.titleLabel.font].width;
    
    CGFloat desiredWidth = fmax(ticketNotResolvedButtonLabelWidth, ticketResolvedButtonLabelWidth) + ADDITIONAL_OFFSET;
    
    if (desiredWidth  > (self.frame.size.width)/2) {
        desiredWidth = (self.frame.size.width)/2 - BUTTON_SPACING;
    }
    
    UIView *leftSpacer = [UIView new];
    leftSpacer.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:leftSpacer];
    
    UIView *rightSpacer = [UIView new];
    rightSpacer.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:rightSpacer];
    
    NSDictionary *views = @{@"ticketResolvedButton" : self.ticketResolvedButton, @"ticketNotResolvedButton" : self.ticketNotResolvedButton,
                            @"promptLabel" : self.promptLabel, @"leftSpacer" : leftSpacer, @"rightSpacer" : rightSpacer};
    
    NSDictionary *metrics = @{ @"desiredWidth" : @(desiredWidth),  @"buttonSpacing" : @(BUTTON_SPACING) };
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[leftSpacer][ticketResolvedButton(desiredWidth)]-buttonSpacing-[ticketNotResolvedButton(desiredWidth)][rightSpacer(leftSpacer)]|" options:NSLayoutFormatAlignAllBaseline metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[promptLabel]-10-[ticketResolvedButton]" options:0 metrics:metrics views:views]];

    
    //http://stackoverflow.com/questions/24731552/assertion-failure-in-myclass-layoutsublayersoflayer
    [super layoutSubviews];

}

-(void)ticketResolvedButtonClicked:(id)sender{
    [self.resolvedPromptViewDelegate handleTicketResolved];
}

-(void)ticketNotResolvedButtonClicked:(id)sender{
    [self.resolvedPromptViewDelegate handleTicketNotResolved];
}

-(CGSize)sizeOfString:(NSString *)string withFont:(UIFont *)font{
    return [string sizeWithAttributes:@{ NSFontAttributeName:font }];
}

@end