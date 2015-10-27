//
//  HLCollectionViewCell.m
//  HotlineSDK
//
//  Created by kirthikas on 22/09/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "HLGridViewCell.h"
#import "HLTheme.h"

@interface HLGridViewCell()

@property (nonatomic,strong) UIView *view;

@end

@implementation HLGridViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = [[UIImageView alloc]init];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.backgroundColor = [[HLTheme sharedInstance] gridViewItemBackgroundColor];
        self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.imageView];
        
        self.label = [[UILabel alloc] init];
        self.label.text = @"Test text";
        self.label.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.label];
        NSDictionary *views = @{ @"imageView" : self.imageView, @"label" : self.label};
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[imageView]-10-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.label attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.imageView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[imageView]-[label]-|" options:0 metrics:nil views:views]];
    }
    return self;
}

-(void)prepareForReuse{
    [super prepareForReuse];
    self.imageView.image=[UIImage imageNamed:@"loading.png"];
}

@end