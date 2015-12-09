//
//  FDMarginalView.m
//  HotlineSDK
//
//  Created by user on 28/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDMarginalView.h"
#import "HLMacros.h"

@interface FDMarginalView ()

@property (nonatomic,strong) UILabel *actionLabel;

@end

@implementation FDMarginalView

-(id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        //CHECK : Remove framecode for label and add missing icon in the marginal view - arvchz
        self.backgroundColor = [UIColor colorWithHue:0.59 saturation:0.67 brightness:0.89 alpha:1];
        self.actionLabel = [[UILabel alloc] initWithFrame:CGRectInset(self.bounds, 60.0f, 0.0f)];
        self.actionLabel.text = HLLocalizedString(@"CONTACT_US_BUTTON_LABEL");
        [self setLabelProperties];
        [self addSubview:self.actionLabel];
        
        NSDictionary *views = @{ @"label":self.actionLabel};
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[label]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]|" options:0 metrics:nil views:views]];
    }
    return self;
}

-(void)setLabelProperties{
    HLTheme *theme = [HLTheme sharedInstance];
    self.actionLabel.textAlignment = UITextAlignmentCenter;
    self.actionLabel.font = [theme talkToUsButtonFont];
    self.actionLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.actionLabel.translatesAutoresizingMaskIntoConstraints=NO;
    self.actionLabel.textColor = [theme talkToUsButtonColor];
    self.actionLabel.userInteractionEnabled=YES;
}

-(void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer{
    [self.actionLabel addGestureRecognizer:gestureRecognizer];
}

@end