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
        self.Button1.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.Button1.titleLabel.numberOfLines = 0;
        self.Button1.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.Button1 addTarget:self.delegate action:@selector(buttonClickedEvent:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.Button1];
        [self setBackgroundColor:[UIColor whiteColor]];
        [self addSpacersInView:self];
        [self setupConstraints];
    }
    return self;
}

-(void)setupConstraints{
    self.buttonLabelWidth = [self getDesiredWidthFor:self.Button1];
    self.views = @{@"Button1" : self.Button1, @"iconView" : self.iconView, @"leftSpacer" : self.leftSpacer, @"rightSpacer" : self.rightSpacer};
    self.metrics = @{ @"buttonLabelWidth" : @(self.buttonLabelWidth),  @"buttonSpacing" : @(BUTTON_SPACING) };
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[iconView]-[Button1]|" options:NSLayoutFormatAlignAllCenterY metrics:self.metrics views:self.views]];
    [self addConstraint:@"V:|[iconView]|" InView:self];
    [self addConstraint:@"V:|[Button1]|" InView:self];
}

-(void)layoutSubviews{
    [self setupConstraints];
    [super layoutSubviews];
}

-(UIImageView *)createImageView{
    UIImageView *imageView = [[UIImageView alloc] init];
    [imageView setContentMode:UIViewContentModeScaleAspectFit];
    [imageView.image drawInRect:CGRectMake(0,0,75,75)];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    return imageView;
}

@end