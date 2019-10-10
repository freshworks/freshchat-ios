//
//  FCReplyCollectionCell.m
//  FreshchatSDK
//
//  Created by Hemanth Kumar on 21/08/19.
//  Copyright © 2019 Freshdesk. All rights reserved.
//

#import "FCReplyCollectionCell.h"
#import "FCTheme.h"
#import "FCMacros.h"

@interface FCReplyCollectionCell ()
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIView *parentView;
@end

@implementation FCReplyCollectionCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    [self addViews];
    return self;
}

-(void) addViews {
    FCTheme* theme = [FCTheme sharedInstance];
    self.parentView = [[UIView alloc] initWithFrame:CGRectZero];
    self.parentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.label = [[UILabel alloc] initWithFrame:CGRectZero];
    [self.label setFont:[theme getQuickReplyMessageFont]];
    [self.label setTextColor: [theme getQuickReplyMessageColor]];
    [self.label setTextAlignment:NSTextAlignmentCenter];
    self.label.translatesAutoresizingMaskIntoConstraints = NO;
    self.label.numberOfLines = 2;
    [self.parentView setBackgroundColor: [theme getQuickReplyCellBackgroundColor]];
    
    self.parentView.layer.cornerRadius = [theme getQuickReplyMessageCornerRadius];
    self.parentView.layer.borderWidth = 1.0;
    self.parentView.layer.borderColor = [UIColor clearColor].CGColor;
    self.parentView.clipsToBounds = YES;
    
    [self.parentView addSubview: self.label];
    [self.contentView addSubview:self.parentView];
    
    NSDictionary* view = @{@"label" : self.label,
                           @"parent": self.parentView};
    
    NSArray *horizontalConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-4-[label]-4-|" options:0 metrics:nil views:view];
    NSArray *verticalConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]|" options:0 metrics:nil views:view];
    
    NSArray *horizontalParentConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[parent]|" options:0 metrics:nil views:view];
    NSArray *verticalParentConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[parent]|" options:0 metrics:nil views:view];
    
    [self.parentView addConstraints: horizontalConstraint];
    [self.parentView addConstraints: verticalConstraint];
    [self.contentView addConstraints: horizontalParentConstraint];
    [self.contentView addConstraints: verticalParentConstraint];
}

-(void) updateLabelText:(NSString *)text {
    [self.label setText:trimString(text)];
}

@end
