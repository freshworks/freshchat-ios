//
//  FDMarginalView.m
//  HotlineSDK
//
//  Created by user on 28/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDMarginalView.h"
#import "HLMacros.h"

@implementation FDMarginalView

-(id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.theme = [HLTheme sharedInstance];
        self.backgroundColor = [UIColor colorWithHue:0.59 saturation:0.67 brightness:0.89 alpha:1];
        self.marginalLabel = [[UILabel alloc] initWithFrame:CGRectInset(self.bounds, 60.0f, 0.0f)];
        self.marginalLabel.textColor = [UIColor whiteColor];
        self.marginalLabel.textAlignment = UITextAlignmentCenter;
        self.marginalLabel.font = [[HLTheme sharedInstance] talkToUsButtonFont];
        self.marginalLabel.translatesAutoresizingMaskIntoConstraints=NO;
        [self addSubview:self.marginalLabel];
        
        NSDictionary *views = @{ @"label":self.marginalLabel};
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[label]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]|" options:0 metrics:nil views:views]];
    }
    return self;
}

-(void)setLabelText:(NSString *)text{
    self.marginalLabel.text = text;
    self.marginalLabel.text = HLLocalizedString(@"CATEGORIES_LIST_VIEW_FOOTER_LABEL");
    self.marginalLabel.textColor = [UIColor blackColor];
    self.marginalLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.marginalLabel.backgroundColor = [UIColor clearColor];
    self.marginalLabel.userInteractionEnabled=YES;
}

@end
