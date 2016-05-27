//
//  FDCell.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 30/03/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FDCell.h"
#import "HLTheme.h"
#import "FDAutolayoutHelper.h"

@implementation FDCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier isChannelCell:(BOOL)isChannel{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        self.isChannelCell = isChannel;
        HLTheme *theme = [HLTheme sharedInstance];
        self.contentEncloser = [[UIView alloc]init];
        self.contentEncloser.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.titleLabel = [[FDLabel alloc] init];
        [self.titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.titleLabel setNumberOfLines:2];
        [self.titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
        
        self.detailLabel = [[FDLabel alloc] init];
        [self.detailLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        if(isChannel){
            if(![theme numberOfChannelListDescriptionLines]){
                [self.detailLabel setNumberOfLines:1];
            }
            else{
                [self.detailLabel setNumberOfLines:[theme numberOfChannelListDescriptionLines]];
            }
        }
        else{
            if(![theme numberOfCategoryListDescriptionLines]){
                [self.detailLabel setNumberOfLines:1];
            }
            else{
                [self.detailLabel setNumberOfLines:[theme numberOfCategoryListDescriptionLines]];
            }
        }
        [self.detailLabel setLineBreakMode:NSLineBreakByTruncatingTail];

        self.imgView=[[UIImageView alloc] init];
        self.imgView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.imgView.layer setMasksToBounds:YES];
        self.imgView.contentMode = UIViewContentModeScaleAspectFit;
        
        //View hierarchy
        [self.contentView addSubview:self.imgView];
        [self.contentView addSubview:self.contentEncloser];
        [self.contentEncloser addSubview:self.titleLabel];
        [self.contentEncloser addSubview:self.detailLabel];

        //Constraints
        NSMutableDictionary *views = [NSMutableDictionary
                                      dictionaryWithDictionary:@{@"imageView" : self.imgView, @"contentEncloser" : self.contentEncloser,
                                                                                     @"title" : self.titleLabel,@"subtitle":self.detailLabel }];

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[imageView(50)]" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[imageView(50)]-[contentEncloser]" options:0 metrics:nil views:views]];
        
        [self.contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[title][subtitle]|" options:0 metrics:nil  views:views]];
        
        self.encloserHeightConstraint = [FDAutolayoutHelper setHeight:0 forView:self.contentEncloser inView:self.contentView];

        [FDAutolayoutHelper centerY:self.contentEncloser onView:self.contentView];
        [FDAutolayoutHelper centerY:self.imgView onView:self.contentView];
        
        UIImageView *accessoryView = [[UIImageView alloc] init];
        accessoryView.image = [[HLTheme sharedInstance] getImageWithKey:IMAGE_TABLEVIEW_ACCESSORY_ICON];
        accessoryView.translatesAutoresizingMaskIntoConstraints=NO;
        [self.contentView addSubview:accessoryView];
        
        [FDAutolayoutHelper centerY:accessoryView onView:self.contentView];
        
        self.rightArrowImageView = accessoryView;
        
        views[@"accessoryView"] = accessoryView;
        
        if (isChannel) {
            self.lastUpdatedLabel = [[UILabel alloc] init];
            self.lastUpdatedLabel.textAlignment = UITextAlignmentRight;
            self.lastUpdatedLabel.translatesAutoresizingMaskIntoConstraints = NO;
            [self.contentView addSubview:self.lastUpdatedLabel];
            
            self.badgeView  = [[FDBadgeView alloc]initWithFrame:CGRectZero];
            self.badgeView.translatesAutoresizingMaskIntoConstraints = NO;
            [self.contentView addSubview:self.badgeView];
            
            views[@"lastUpdated"] = self.lastUpdatedLabel;
            views[@"badgeView"] = self.badgeView;
            
            [self.contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[title]|" options:0 metrics:nil views:views]];
            [self.contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[subtitle]" options:0 metrics:nil views:views]];
            
            self.lastUpdatedTimeWidthConstraint = [FDAutolayoutHelper setWidth:55 forView:self.lastUpdatedLabel inView:self.contentView];
            
            self.detailLableRightConstraint = [NSLayoutConstraint constraintWithItem:self.detailLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.contentEncloser attribute:NSLayoutAttributeTrailing multiplier:1 constant:0];
            
            [self.contentEncloser addConstraint:self.detailLableRightConstraint];
            
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[badgeView(30)]-10-[accessoryView(6)]-10-|" options:0 metrics:nil views:views]];
            
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[lastUpdated(15)]-5-[badgeView(20)]" options:0 metrics:nil views:views]];
            
            [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.lastUpdatedLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:accessoryView attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
            
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[contentEncloser][lastUpdated]" options:0 metrics:nil views:views]];

        }else{
            [self.contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[title]|" options:0 metrics:nil views:views]];
            [self.contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[subtitle]|" options:0 metrics:nil views:views]];
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[contentEncloser]-[accessoryView(6)]-10-|" options:0 metrics:nil views:views]];
        }
        
        [self theme];
    }
    return self;
}

-(void)adjustPadding{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setNeedsLayout];
        [self layoutIfNeeded];

        CGFloat titleHeight  = self.titleLabel.intrinsicContentSize.height;
        CGFloat detailHeight = self.detailLabel.intrinsicContentSize.height;
        
        CGFloat lastUpdatedTimeWidth = self.lastUpdatedLabel.intrinsicContentSize.width;
        
        self.lastUpdatedTimeWidthConstraint.constant = lastUpdatedTimeWidth;
        self.encloserHeightConstraint.constant = titleHeight + detailHeight;
        
        if (self.badgeView.isHidden) {
            self.detailLableRightConstraint.constant = lastUpdatedTimeWidth - self.rightArrowImageView.frame.size.width;
        }else{
            self.detailLableRightConstraint.constant = 0;
        }
    });
}

-(void)theme{
    HLTheme *theme = [HLTheme sharedInstance];
    if (self.isChannelCell) {
        self.backgroundColor     = [theme channelListCellBackgroundColor];
        self.titleLabel.textColor = [theme channelTitleFontColor];
        self.titleLabel.font      = [theme channelTitleFont];
        self.detailLabel.font = [theme channelDescriptionFont];
        self.detailLabel.textColor = [theme channelDescriptionFontColor];
        self.lastUpdatedLabel.font = [theme channelLastUpdatedFont];
        self.lastUpdatedLabel.textColor = [theme channelLastUpdatedFontColor];
    }else{
        self.backgroundColor = [theme tableViewCellBackgroundColor];
        self.titleLabel.textColor = [theme tableViewCellTitleFontColor];
        self.titleLabel.font      = [theme tableViewCellTitleFont];
        self.detailLabel.font = [theme tableViewCellDetailFont];
        self.detailLabel.textColor = [theme tableViewCellDetailFontColor];
    }
}

+(UIImage *)generateImageForLabel:(NSString *)labelText{
    HLTheme *theme = [HLTheme sharedInstance];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    NSString *firstLetter = [labelText substringToIndex:1];
    firstLetter = [firstLetter uppercaseString];
    label.text = firstLetter;
    label.font = [theme channelIconPlaceholderImageCharFont];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [theme channelIconPalceholderImageBackgroundColor];
    label.layer.cornerRadius = label.frame.size.height / 2.0f;
    label.clipsToBounds = YES;
    UIGraphicsBeginImageContext(label.frame.size);
    [[label layer] renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


-(void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    //TODO: add a check for category list
    self.layer.borderWidth = 0.6;
    self.imgView.layer.cornerRadius = self.imgView.frame.size.width / 2;
    self.imgView.layer.masksToBounds = YES;
    self.layer.borderColor = [[HLTheme sharedInstance] tableViewCellSeparatorColor].CGColor;
}

@end