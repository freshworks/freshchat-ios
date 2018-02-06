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
#import "FDUtilities.h"

@interface FDBadgeView ()

@end

@implementation FDBadgeView

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        FCTheme *theme = [FCTheme sharedInstance];
        self.countLabel = [FDLabel new];
        self.countLabel.textAlignment = NSTextAlignmentNatural;
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
        NSString *andMoreStr = @"";//Empty
        if(count >99){
            andMoreStr = @"+";
            count = 99;
        }
        NSNumber *countNumber = [NSNumber numberWithInteger:count];
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        NSLocale *curAppLocale = [NSLocale localeWithLocaleIdentifier:[[NSBundle mainBundle] preferredLocalizations].firstObject];
        //Get language that app is using and get locale object from that- https://developer.apple.com/library/content/documentation/MacOSX/Conceptual/BPInternational/InternationalizingLocaleData/InternationalizingLocaleData.html
        [formatter setLocale:curAppLocale];
        self.countLabel.text = [FDUtilities isDeviceLanguageRTL] ? [andMoreStr stringByAppendingString:[formatter stringFromNumber:countNumber]] :
        [[formatter stringFromNumber:countNumber] stringByAppendingString:andMoreStr]; ;
        self.hidden = NO;
    }else{
        self.hidden = YES;
    }
}

@end
