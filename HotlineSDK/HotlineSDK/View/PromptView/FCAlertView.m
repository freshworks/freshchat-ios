//
//  FDAlertView.m
//  FreshdeskSDK
//
//  Created by Arvchz on 23/02/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FCAlertView.h"
#import "FCMacros.h"
#import "FCTheme.h"
#import "FCLocalization.h"

@interface FCAlertView ()

@property (nonatomic, strong) UIImageView* iconView;
@property (nonatomic, assign) CGFloat buttonLabelWidth;
@property (weak, nonatomic) id <FCAlertViewDelegate> delegate;

@end

@implementation FCAlertView

-(instancetype)initWithDelegate:(id <FCAlertViewDelegate>)delegate andKey:(NSString *)key{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        
        self.promptLabel = [self createPromptLabel:key];
        [self addSubview:self.promptLabel];
        
        self.contactUsBtn = [self createPromptButton:@"contact_us" withKey:key];
        [self.contactUsBtn setTitleColor:[[FCTheme sharedInstance] dialogueButtonColor] forState:UIControlStateNormal];
        [self.contactUsBtn addTarget:self.delegate action:@selector(buttonClickedEvent:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.contactUsBtn];
        self.contactUsBtn.backgroundColor = [[FCTheme sharedInstance] talkToUsButtonBackgroundColor];
        [self addSpacersInView:self];
    }
    return self;
}

-(void)setupConstraints{
    self.buttonLabelWidth = [self getDesiredWidthFor:self.contactUsBtn];
    self.views = @{@"Button1" : self.contactUsBtn, @"Prompt":self.promptLabel};
    float buttonHeight = self.contactUsBtn.isHidden ? 0 : self.contactUsBtn.intrinsicContentSize.height+5;//% added for better size
    self.metrics = @{ @"buttonHeight" : @(buttonHeight) };
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[Button1]|" options:NSLayoutFormatAlignAllCenterY metrics:self.metrics views:self.views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[Prompt]|" options:0 metrics:self.metrics views:self.views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[Prompt][Button1(buttonHeight)]|" options:0 metrics:self.metrics views:self.views]];
}

-(void)layoutSubviews{
    [self setupConstraints];
    [super layoutSubviews];
}

-(CGFloat)getPromptHeight{
    return ALERT_PROMPT_VIEW_HEIGHT;
}

@end
