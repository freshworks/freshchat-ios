//
//  FDBadgeView.m
//  FreshdeskSDK
//
//  Created by Meera Sundar on 02/06/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDBadgeView.h"
#import "FCTheme.h"
#import "FDAutolayoutHelper.h"

@interface FDBadgeView ()

@end

@implementation FDBadgeView

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        FCTheme *theme = [FCTheme sharedInstance];
        self.countLabel = [FDLabel new];
        self.countLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.countLabel.textColor = [theme badgeButtonTitleColor];
        self.backgroundColor = [theme badgeButtonBackgroundColor];
        self.countLabel.font = [theme badgeButtonFont];
        [self addSubview:self.countLabel];
        [FDAutolayoutHelper center:self.countLabel onView:self];
    }
    return self;
}

-(void)drawRect:(CGRect)rect{
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = self.frame.size.width/3;
}

-(void)updateBadgeCount:(NSInteger)count{
    if (count) {
        NSString *countString = [NSString stringWithFormat:@"%ld",(long)count];
        if (count > 99) countString = [NSString stringWithFormat:@"99+"];
        self.countLabel.text = countString;
        self.hidden = NO;
    }else{
        self.hidden = YES;
    }
}

@end
