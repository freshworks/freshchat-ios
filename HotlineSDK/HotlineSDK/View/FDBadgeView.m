//
//  FDBadgeView.m
//  FreshdeskSDK
//
//  Created by Meera Sundar on 02/06/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDBadgeView.h"
#import "HLTheme.h"

@interface FDBadgeView ()

@end

@implementation FDBadgeView

-(instancetype)initWithFrame:(CGRect)frame andBadgeNumber:(NSInteger)count{
    self = [super initWithFrame:frame];
    if (self) {
        HLTheme *theme = [HLTheme sharedInstance];
        self.badgeButton                    = [UIButton buttonWithType:UIButtonTypeCustom];
        self.badgeButton.backgroundColor    = [theme badgeButtonBackgroundColor];
        self.badgeButton.layer.cornerRadius = 13.0;
        self.badgeButton.titleLabel.font    = [theme badgeButtonFont];
        NSString *countString               = [NSString stringWithFormat:@"%ld",(long)count];
        if (count > 999) countString = [NSString stringWithFormat:@"999+"];
        [self.badgeButton setTitle:countString forState:UIControlStateNormal];
        [self.badgeButton setTitleColor:[theme badgeButtonTitleColor] forState:UIControlStateNormal];
        [self.badgeButton sizeToFit];
    }
    return self;
}

-(void)updateBadgeCount:(NSInteger)count{
    if (count) {
        NSString *countString = [NSString stringWithFormat:@"%ld",(long)count];
        [self.badgeButton setTitle:countString forState:UIControlStateNormal];
        [self.badgeButton sizeToFit];
        [self.badgeButton.layer setCornerRadius:self.badgeButton.frame.size.width/3];
        [self.badgeButton setHidden:NO];
    }else{
        [self.badgeButton setHidden:YES];
    }
}

@end