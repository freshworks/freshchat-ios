//
//  FDBadgeView.m
//  FreshdeskSDK
//
//  Created by Meera Sundar on 02/06/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDBadgeView.h"

@interface FDBadgeView ()

@end

@implementation FDBadgeView

-(instancetype)initWithFrame:(CGRect)frame andBadgeNumber:(NSInteger)count{
    self = [super initWithFrame:frame];
    if (self) {
        self.badgeButton                    = [UIButton buttonWithType:UIButtonTypeCustom];
        self.badgeButton.backgroundColor    = [UIColor redColor];
        self.badgeButton.layer.cornerRadius = 13.0;
        self.badgeButton.titleLabel.font    = [UIFont boldSystemFontOfSize:12.0];
        NSString *countString               = [NSString stringWithFormat:@"%ld",(long)count];
        if (count > 999) countString = [NSString stringWithFormat:@"999+"];
        [self.badgeButton setTitle:countString forState:UIControlStateNormal];
        [self.badgeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.badgeButton sizeToFit];
    }
    return self;
}

-(void)badgeButtonBackgroundColor:(UIColor *)color{
    self.badgeButton.backgroundColor = color;
}

-(void)badgeButtonTitleColor:(UIColor *)color{
    [self.badgeButton setTitleColor:color forState:UIControlStateNormal];
}

-(void)updateBadgeCount:(NSInteger)count{
    if (count) {
        NSString *countString = [NSString stringWithFormat:@"%ld",(long)count];
        [self.badgeButton setTitle:countString forState:UIControlStateNormal];
        [self.badgeButton sizeToFit];
        [self.badgeButton setHidden:NO];
    }else{
        [self.badgeButton setHidden:YES];
    }
}

@end