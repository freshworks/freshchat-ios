//
//  FDMarginalView.m
//  HotlineSDK
//
//  Created by user on 28/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDMarginalView.h"
#import "HLMacros.h"
#import "HLLocalization.h"
#import "FDAutolayoutHelper.h"

@interface FDMarginalView ()

@property (nonatomic,strong) UIImageView *contactUsImgView;
@property (nonatomic,strong) UILabel *actionLabel;
@property (nonatomic,strong) id<FDMarginalViewDelegate> delegate;

@end

@implementation FDMarginalView

-(id)initWithDelegate:(id <FDMarginalViewDelegate>)delegate{
    self = [super init];
    if (self) {
        HLTheme *theme = [HLTheme sharedInstance];

        self.delegate = delegate;
        self.userInteractionEnabled = YES;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.backgroundColor = [theme talkToUsButtonBackgroundColor];
        UIGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
        [self addGestureRecognizer:tapGesture];
        
        self.contactUsImgView = [[UIImageView alloc] init];
        self.contactUsImgView.translatesAutoresizingMaskIntoConstraints = NO;
        self.contactUsImgView.image = [theme getImageWithKey:IMAGE_CONTACT_US_LIGHT_ICON];
        [self addSubview:self.contactUsImgView];
        
        self.actionLabel = [[UILabel alloc] init];
        self.actionLabel.text = HLLocalizedString(LOC_CONTACT_US_BUTTON_TEXT);
        self.actionLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.actionLabel.textAlignment = UITextAlignmentCenter;
        self.actionLabel.font = [theme talkToUsButtonFont];
        self.actionLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.actionLabel.textColor = [theme talkToUsButtonTextColor];
        [self addSubview:self.actionLabel];
        
        [self addConstraint: [FDAutolayoutHelper centerY:self.contactUsImgView onView:self]];
        
        [FDAutolayoutHelper center:self.actionLabel onView:self];
        
        NSDictionary *views = @{@"contactusIcon":self.contactUsImgView, @"contactusLabel":self.actionLabel};
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[contactusIcon(12)]" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[contactusIcon(12)]-5-[contactusLabel]" options:0 metrics:nil views:views]];
    }
    return self;
}

-(void)handleTapGesture:(id)sender{
    [self.delegate marginalView:self handleTap:sender];
}

@end