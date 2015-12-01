//
//  FDChannelListViewCell.m
//  HotlineSDK
//
//  Created by user on 29/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDChannelListViewCell.h"

@implementation FDChannelListViewCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.theme = [HLTheme sharedInstance];
        
        self.layer.borderWidth = 0.6;
        self.layer.borderColor = [[HLTheme sharedInstance] tableViewCellSeparatorColor].CGColor;
        
        self.imgView.layer.cornerRadius = self.imgView.frame.size.width / 2;
        self.imgView.layer.masksToBounds = YES;
        
        self.lastUpdatedLabel = [[UILabel alloc] initWithFrame:CGRectMake(253, 76.5, 52.5, 23.5)];
        self.lastUpdatedLabel.font = [self.theme tableViewCellDetailFont];
        self.lastUpdatedLabel.textColor = [self.theme tableViewCellDetailFontColor];
        self.lastUpdatedLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.lastUpdatedLabel];
        
        self.badgeView  = [[FDBadgeView alloc]initWithFrame:CGRectMake(257, 98, 31.5, 21)
                                             andBadgeNumber:0];
        [self.badgeView badgeButtonBackgroundColor:[UIColor colorWithHue:0.59 saturation:0.67 brightness:0.89 alpha:1]];
        [self.badgeView badgeButtonTitleColor:[self.theme badgeButtonTitleColor]];
        self.badgeView.translatesAutoresizingMaskIntoConstraints = NO;
        self.badgeView.badgeButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.badgeView.badgeButton];
        [self.contentView addSubview:self.badgeView];
        
        self.accessoryButton = [[UIImageView alloc] init];
        self.accessoryButton.image = [HLTheme getImageFromMHBundleWithName:@"rightArrow.png"];
        self.accessoryButton.translatesAutoresizingMaskIntoConstraints=NO;
        [self.contentView addSubview:self.accessoryButton];
        
        
        NSDictionary *views = @{@"lastUpdated":self.lastUpdatedLabel,@"badgeView":self.badgeView.badgeButton,@"accessoryButton":self.accessoryButton};
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[lastUpdated]-10-[badgeView(21)]" options:NSLayoutFormatAlignAllLeft metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[lastUpdated]-10-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[badgeView(32)]-[accessoryButton(6)]" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
    
        [self setupTheme];
    }
    return self;
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

-(void)setupTheme{
    if (self) {
        self.backgroundColor     = [self.theme tableViewCellBackgroundColor];
        self.titleLabel.textColor = [self.theme tableViewCellFontColor];
        self.titleLabel.font      = [self.theme tableViewCellFont];
        self.detailLabel.textColor = [self.theme timeDetailTextColor];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imgView.layer.cornerRadius = self.imgView.frame.size.width / 2;
    self.imgView.layer.masksToBounds = YES;
    
}

-(void)prepareForReuse{
    [super prepareForReuse];
    self.imgView.image=[UIImage imageNamed:@"loading.png"];
}

@end