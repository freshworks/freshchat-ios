//
//  HLEmptyResultView.m
//  HotlineSDK
//
//  Created by Harish Kumar on 08/03/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "HLEmptyResultView.h"
#import "HLTheme.h"

@implementation HLEmptyResultView


-(id)initWithImage:(UIImage *)image andText:(NSString *)text {
    self = [super init];
    if (self) {
        
        HLTheme *theme = [HLTheme sharedInstance];
        self.emptyResultImage = [[UIImageView alloc] init];
        self.emptyResultImage.image = image;
        [self.emptyResultImage setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview:self.emptyResultImage];
        
        self.emptyResultLabel = [[UILabel alloc]init];
        self.emptyResultLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.emptyResultLabel.textColor = [theme emptyResultMessageFontColor];
        self.emptyResultLabel.font = [theme emptyResultMessageFont];
        self.emptyResultLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.emptyResultLabel.numberOfLines = 3;
        self.emptyResultLabel.textAlignment= NSTextAlignmentCenter;
        self.emptyResultLabel.text = text;
        [self addSubview:self.emptyResultLabel];
        
        NSDictionary *views = @{@"emptyResultImageView":self.emptyResultImage, @"emptyResultLabel":self.emptyResultLabel};
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[emptyResultLabel(240)]" options:0 metrics:nil views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[emptyResultImageView(100)]" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[emptyResultImageView(100)]-10-[emptyResultLabel]" options:0 metrics:nil views:views]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.emptyResultImage
                                                              attribute:NSLayoutAttributeCenterX
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self
                                                              attribute:NSLayoutAttributeCenterX
                                                             multiplier:1.0
                                                               constant:0.0]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.emptyResultLabel
                                                              attribute:NSLayoutAttributeCenterX
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self
                                                              attribute:NSLayoutAttributeCenterX
                                                             multiplier:1.0
                                                               constant:0.0]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.emptyResultImage
                                                              attribute:NSLayoutAttributeCenterY
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self
                                                              attribute:NSLayoutAttributeCenterY
                                                             multiplier:0.5
                                                               constant:0.0]];
    }
    return self;
}




/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
