//
//  FCFooterView.m
//  FreshchatSDK
//
//  Created by user on 04/12/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCFooterView.h"
#import "FDUtilities.h"
#import "FDAutolayoutHelper.h"

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
        if([FDUtilities isPoweredByFooterViewHidden]){
            self.footerLabel.text = @"";
        }
        else{
            self.footerLabel.text = @"Powered by Freshchat";
        }
        self.footerLabel.font = [UIFont systemFontOfSize:11];
        [self addSubview:self.footerLabel];
        if([FDUtilities isIPhoneXView] && !isEmbed){
            [FDAutolayoutHelper centerX:self.footerLabel onView:self];
            [FDAutolayoutHelper centerY:self.footerLabel onView:self M:0.60 C:0];
        }
        else{
            [FDAutolayoutHelper center:self.footerLabel onView:self];
        }
    }
    return self;
}

-(void)setViewColor:(UIColor*) color{
    self.backgroundColor = color;
    self.footerLabel.textColor = [FDUtilities invertColor:color];
}

@end
