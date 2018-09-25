//
//  FCFooterView.m
//  FreshchatSDK
//
//  Created by user on 04/12/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCFooterView.h"
#import "FCUtilities.h"
#import "FCAutolayoutHelper.h"

@implementation FCFooterView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initFooterViewWithEmbedded :(BOOL)isEmbed{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.footerLabel = [UILabel new];
        self.footerLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.footerLabel.font = [UIFont systemFontOfSize:11];
        [self addSubview:self.footerLabel];
        if([FCUtilities hasNotchDisplay] && !isEmbed){
            [FCAutolayoutHelper centerX:self.footerLabel onView:self];
            [FCAutolayoutHelper centerY:self.footerLabel onView:self M:0.60 C:0];
        }
        else{
            [FCAutolayoutHelper center:self.footerLabel onView:self];
        }
        if([FCUtilities isPoweredByFooterViewHidden]){
            self.footerLabel.text = @"";
        }
        else{
            self.footerLabel.text = @"Powered by Freshchat";
        }
    }
    return self;
}

-(void)setViewColor:(UIColor*) color{
    self.backgroundColor = color;
    self.footerLabel.textColor = [FCUtilities invertColor:color];
}

@end
