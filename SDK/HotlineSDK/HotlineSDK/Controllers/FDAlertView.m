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
@property (nonatomic, strong) UIButton *Button1;
@property CGFloat buttonLabelWidth;
@property (weak, nonatomic) id <FDAlertViewDelegate> delegate;

@end

@implementation FDAlertView

-(instancetype)initWithDelegate:(id <FDAlertViewDelegate>)delegate andKey:(NSString *)key{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.iconView = [self createImageView];
        self.iconView.image = [UIImage imageNamed:@"message.png"];
        [self addSubview:self.iconView];
        
        self.Button1 = [self createPromptButton:@"Button" withKey:key];
        [self.Button1 addTarget:self.delegate action:@selector(buttonClickedEvent:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.Button1];
        
        [self addSpacersInView:self];
    }
    return self;
}

-(void)layoutSubviews{
    
    self.buttonLabelWidth = [self getDesiredWidthFor:self.Button1];
    self.views = @{@"Button1" : self.Button1, @"iconView" : self.iconView, @"leftSpacer" : self.leftSpacer, @"rightSpacer" : self.rightSpacer};
    self.metrics = @{ @"buttonLabelWidth" : @(self.buttonLabelWidth),  @"buttonSpacing" : @(BUTTON_SPACING) };
    
    [self addConstraintWithBaseLine:@"H:|-[iconView][Button1(buttonLabelWidth)]-|" inView:self];
    [self addConstraint:@"V:|[iconView]|" InView:self];
    [self addConstraint:@"V:|[Button1]|" InView:self];
    [super layoutSubviews];

}

-(UIImageView *)createImageView{
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 75, 75)];
    [imageView setContentMode:UIViewContentModeScaleAspectFit];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    return imageView;
}

@end