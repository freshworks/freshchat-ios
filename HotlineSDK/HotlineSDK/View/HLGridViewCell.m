//
//  HLCollectionViewCell.m
//  HotlineSDK
//
//  Created by kirthikas on 22/09/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "HLGridViewCell.h"
#import "FCTheme.h"
#import "FDAutolayoutHelper.h"

@interface HLGridViewCell()

@property (nonatomic,strong) UIView *view;

@property (nonatomic, strong) FCTheme *theme;

@end

@implementation HLGridViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.cardView = [[UIView alloc] init];
        self.cardView.layer.cornerRadius = 10;
        self.cardView.layer.masksToBounds = true;
        
        self.cardView.translatesAutoresizingMaskIntoConstraints = NO;
        self.cardView.backgroundColor = [[FCTheme sharedInstance] gridViewCardBackgroundColor];
        
        self.cardView.layer.masksToBounds = NO;
        self.cardView.layer.shadowColor = [[FCTheme sharedInstance] gridViewCardShadowColor].CGColor;
        self.cardView.layer.shadowOffset = CGSizeMake(-0.0f, -0.0f);
        self.cardView.layer.shadowOpacity = 0.6f;
            
        self.imageView = [[UIImageView alloc]init];
        self.theme = [FCTheme sharedInstance];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.backgroundColor = [UIColor clearColor];
        self.imageView.clipsToBounds = YES;
        self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.cardView addSubview:self.imageView];
    
        self.label = [[UILabel alloc]init];
        self.label.font = [self.theme faqCategoryTitleFont];
        self.label.lineBreakMode=NSLineBreakByTruncatingTail;
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.backgroundColor = [UIColor clearColor];
        self.label.textColor = [self.theme faqCategoryTitleFontColor];
        [self.label  setNumberOfLines:2];
        [self.label sizeToFit];
        self.label.translatesAutoresizingMaskIntoConstraints = NO;
        [self.cardView addSubview:self.label];
        
        [self.contentView addSubview:self.cardView];
        
        UILongPressGestureRecognizer *tapRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewTap:)];
        tapRecognizer.minimumPressDuration = 0.01;//To add minimun interval in touch gesture
        tapRecognizer.cancelsTouchesInView = NO;
        [self.cardView addGestureRecognizer:tapRecognizer];
        
        NSDictionary *views = @{ @"imageView" : self.imageView, @"label" : self.label, @"cardView": self.cardView};

        
        [FDAutolayoutHelper centerX:self.imageView onView:self.contentView];
        [FDAutolayoutHelper centerY:self.imageView onView:self.contentView M:0.8 C:0];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.imageView
                                                                     attribute:NSLayoutAttributeWidth
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.contentView
                                                                     attribute:NSLayoutAttributeWidth
                                                                    multiplier:0.4
                                                                      constant:0]];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.imageView
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.contentView
                                                                     attribute:NSLayoutAttributeHeight
                                                                    multiplier:0.4
                                                                      constant:0]];
        
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[cardView]-10-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[cardView]-10-|" options:0 metrics:nil views:views]];
        
        [self.cardView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[label]-|" options:0 metrics:nil views:views]];
        [self.cardView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[imageView]-[label]-5-|" options:0 metrics:nil views:views]];
    }
    return self;
}

- (void)handleViewTap:(UITapGestureRecognizer*)sender {
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
        {
            self.cardView.backgroundColor = [[FCTheme sharedInstance] faqListCellSelectedColor];
            break;
        }
        
        case UIGestureRecognizerStateEnded:
        {
            self.cardView.backgroundColor = [[FCTheme sharedInstance] gridViewCardBackgroundColor];
            break;
        }
            
        default:
            self.cardView.backgroundColor = [[FCTheme sharedInstance] gridViewCardBackgroundColor];
            break;
    }
}

-(void)prepareForReuse{
    [super prepareForReuse];
}

-(void)layoutSubviews{
    [super layoutSubviews];
    self.label.preferredMaxLayoutWidth = self.bounds.size.width;
    [self.view layoutIfNeeded];
}

@end
