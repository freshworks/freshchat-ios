//
//  FDChannelListViewCell.m
//  HotlineSDK
//
//  Created by user on 29/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDChannelListViewCell.h"
#import "HLtheme.h"

@interface FDChannelListViewCell ()

@property (strong, nonatomic) HLTheme *theme;

@end

@implementation FDChannelListViewCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.theme = [HLTheme sharedInstance];
        self.backgroundColor     = [self.theme tableViewCellBackgroundColor];
        self.titleLabel.textColor = [self.theme tableViewCellFontColor];
        self.titleLabel.font      = [self.theme tableViewCellFont];
        self.detailLabel.textColor = [self.theme timeDetailTextColor];
    }
    return self;
}

-(void)addAccessoryView{
    
    UIImageView *accessoryView = [[UIImageView alloc] init];
    accessoryView.image = [HLTheme getImageFromMHBundleWithName:@"rightArrow"];
    accessoryView.translatesAutoresizingMaskIntoConstraints=NO;
    [self.contentView addSubview:accessoryView];

    self.lastUpdatedLabel = [[UILabel alloc] init];
    self.lastUpdatedLabel.font = [self.theme tableViewCellDetailFont];
    self.lastUpdatedLabel.textColor = [self.theme tableViewCellDetailFontColor];
    self.lastUpdatedLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.lastUpdatedLabel];
    
    self.badgeView  = [[FDBadgeView alloc]initWithFrame:CGRectZero andBadgeNumber:0];
    [self.badgeView badgeButtonBackgroundColor:[UIColor colorWithHue:0.59 saturation:0.67 brightness:0.89 alpha:1]];
    [self.badgeView badgeButtonTitleColor:[self.theme badgeButtonTitleColor]];
    self.badgeView.translatesAutoresizingMaskIntoConstraints = NO;
    self.badgeView.badgeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.badgeView.badgeButton];
    [self.contentView addSubview:self.badgeView];
        
    NSDictionary *views = @{@"lastUpdated":self.lastUpdatedLabel,@"badgeView":self.badgeView.badgeButton,@"accessoryView":accessoryView,
                            @"contentEncloser" : self.contentEncloser};
    
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[contentEncloser]-[lastUpdated]" options:0 metrics:nil views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[lastUpdated(15)]-5-[badgeView(21)]" options:NSLayoutFormatAlignAllCenterX metrics:nil views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[lastUpdated(70)][accessoryView(6)]-10-|" options:0 metrics:nil views:views]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual toItem:accessoryView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
}


+(UIImage *)generateImageForLabel:(NSString *)labelText{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    NSString *firstLetter = [labelText substringToIndex:1];
    firstLetter = [firstLetter uppercaseString];
    label.text = firstLetter;
    label.font = [UIFont boldSystemFontOfSize:16];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor lightGrayColor];
    label.layer.cornerRadius = label.frame.size.height / 2.0f;
    UIGraphicsBeginImageContext(label.frame.size);
    [[label layer] renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

-(void)prepareForReuse{
    [super prepareForReuse];
    //TODO: Loading image from theme
    self.imgView.image=[UIImage imageNamed:@"loading"];
}

-(void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    self.layer.borderWidth = 0.6;
    self.imgView.layer.cornerRadius = self.imgView.frame.size.width / 2;
    self.imgView.layer.masksToBounds = YES;
    self.layer.borderColor = [[HLTheme sharedInstance] tableViewCellSeparatorColor].CGColor;
}

@end