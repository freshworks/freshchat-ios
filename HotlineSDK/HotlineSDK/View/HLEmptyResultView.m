//
//  HLEmptyResultView.m
//  HotlineSDK
//
//  Created by Harish Kumar on 08/03/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "HLEmptyResultView.h"
#import "FCTheme.h"
#import "FDAutolayoutHelper.h"

@implementation HLEmptyResultView

-(id)initWithImage:(UIImage *)image withType:(enum SupportType)solType andText:(NSString *)text {
    self = [super init];
    if (self) {
        
        FCTheme *theme = [FCTheme sharedInstance];
        self.emptyResultImage = [[UIImageView alloc] init];
        self.emptyResultImage.image = image;
        [self.emptyResultImage setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview:self.emptyResultImage];
        
        self.emptyResultLabel = [[UILabel alloc]init];
        self.emptyResultLabel.translatesAutoresizingMaskIntoConstraints = NO;
        if(solType == SOLUTIONS){
            self.emptyResultLabel.textColor = [theme faqEmptyResultMessageFontColor];
            self.emptyResultLabel.font = [theme faqEmptyResultMessageFont];
        }
        else{
            self.emptyResultLabel.textColor = [theme channelEmptyResultMessageFontColor];
            self.emptyResultLabel.font = [theme channelEmptyResultMessageFont];
        }
        self.emptyResultLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.emptyResultLabel.numberOfLines = 3;
        self.emptyResultLabel.textAlignment= NSTextAlignmentCenter;
        self.emptyResultLabel.text = text;
        [self addSubview:self.emptyResultLabel];
        
        NSDictionary *views = @{@"emptyResultImageView":self.emptyResultImage, @"emptyResultLabel":self.emptyResultLabel};
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[emptyResultLabel(240)]" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[emptyResultImageView(100)]" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[emptyResultImageView(100)]-10-[emptyResultLabel]" options:0 metrics:nil views:views]];
        
        [FDAutolayoutHelper centerX:self.emptyResultLabel onView:self];
        [FDAutolayoutHelper centerX:self.emptyResultImage onView:self];
        [FDAutolayoutHelper centerY:self.emptyResultImage onView:self M:0.5 C:0.0];
    }
    return self;
}

@end
