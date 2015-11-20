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
        
        self.imgView.layer.cornerRadius = self.imgView.frame.size.width / 2;
        self.imgView.layer.masksToBounds = YES;
        
        self.lastUpdatedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 75, 75)];
        self.lastUpdatedLabel.font = [self.theme tableViewCellDetailFont];
        self.lastUpdatedLabel.textColor = [self.theme tableViewCellDetailFontColor];
        self.lastUpdatedLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.lastUpdatedLabel];
        
        self.badgeView  = [[FDBadgeView alloc]initWithFrame:CGRectZero andBadgeNumber:0];
        [self.badgeView badgeButtonBackgroundColor:[self.theme badgeButtonBackgroundColor]];
        [self.badgeView badgeButtonTitleColor:[self.theme badgeButtonTitleColor]];
        self.badgeView.translatesAutoresizingMaskIntoConstraints = NO;
        self.badgeView.badgeButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.badgeView.badgeButton];
        [self.contentView addSubview:self.badgeView];
        
        self.accessoryButton = [[UIImageView alloc] init];
        self.accessoryButton.image = [UIImage imageNamed:@"arrow.jpg"];
        self.accessoryButton.translatesAutoresizingMaskIntoConstraints=NO;
        [self.contentView addSubview:self.accessoryButton];
        
        
        NSDictionary *views = @{@"lastUpdated":self.lastUpdatedLabel,@"badgeView":self.badgeView.badgeButton,@"accessoryButton":self.accessoryButton};
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[lastUpdated]-10-[badgeView]" options:NSLayoutFormatAlignAllLeft metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[lastUpdated]-10-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[badgeView]-[accessoryButton(25)]" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
    
        [self setupTheme];
    }
    return self;
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
    
}

-(void)prepareForReuse{
    [super prepareForReuse];
    self.imgView.image=[UIImage imageNamed:@"loading.png"];
}


@end
