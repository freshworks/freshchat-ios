//
//  FDAlertView.m
//  FreshdeskSDK
//
//  Created by Arvchz on 23/02/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FDAlertView.h"
#import "HLMacros.h"
#import "HLTheme.h"

@interface FDAlertView ()

@property (nonatomic,strong) UIImageView* iconView;
@property CGFloat buttonLabelWidth;
@property (weak, nonatomic) id <FDAlertViewDelegate> delegate;

@end

@implementation FDAlertView

-(instancetype)initWithDelegate:(id <FDAlertViewDelegate>)delegate andKey:(NSString *)key{
    self = [super init];
    if (self) {
        self.delegate = delegate;
//        self.iconView = [self createImageView];
//        self.iconView.image = [UIImage imageNamed:@"message.png"];
//        [self addSubview:self.iconView];
        
        self.promptLabel = [self createPromptLabel];
        self.promptLabel.text = HLLocalizedString(([NSString stringWithFormat:@"%@_TEXT",key]));
        [self addSubview:self.promptLabel];
        
        self.Button1 = [self createPromptButton:@"BUTTON" withKey:key];
        //TODO: Move this to theme file - Rex
        [self.Button1 setTitleColor:[[HLTheme sharedInstance] dialogueButtonColor] forState:UIControlStateNormal];
        [self.Button1 addTarget:self.delegate action:@selector(buttonClickedEvent:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.Button1];
        [self setBackgroundColor:[UIColor whiteColor]];
        [self addSpacersInView:self];
    }
    return self;
}

-(void)setupConstraints{
    self.buttonLabelWidth = [self getDesiredWidthFor:self.Button1];
    self.views = @{@"Button1" : self.Button1, @"Prompt":self.promptLabel};
    self.metrics = @{ @"buttonLabelWidth" : @(self.buttonLabelWidth),  @"buttonSpacing" : @(BUTTON_SPACING) };
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[Button1]|" options:NSLayoutFormatAlignAllCenterY metrics:self.metrics views:self.views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[Prompt]|" options:0 metrics:self.metrics views:self.views]];
    [self addConstraint:@"V:|[Prompt][Button1]|" InView:self];
}

-(void)layoutSubviews{
    [self setupConstraints];
    [super layoutSubviews];
}

-(CGFloat)getPromptHeight{
    return ALERT_PROMPT_VIEW_HEIGHT;
}

@end