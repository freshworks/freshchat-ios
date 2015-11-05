//
//  FDCategoryTableViewCell.m
//  HotlineSDK
//
//  Created by user on 27/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDTableViewCellWithImage.h"

@implementation FDTableViewCellWithImage

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.theme = [HLTheme sharedInstance];
        
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        for (id view in [self.subviews[0] subviews]) {
            if ([view isKindOfClass:[UIButton class]]) {
                UIButton *accessoryButton = (UIButton *)view;
                accessoryButton.backgroundColor = nil;
            }
        }
        
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.font = [self.theme tableViewCellDetailFont];
        self.titleLabel.textColor = [self.theme tableViewCellDetailFontColor];
        
        self.imgView=[[UIImageView alloc] init];
        self.imgView.backgroundColor=[self.theme tableViewCellImageBackgroundColor];
        [self.imgView.layer setCornerRadius:8.0f];
        [self.imgView.layer setMasksToBounds:YES];
        self.imgView.contentMode = UIViewContentModeScaleAspectFit;
        [self.imgView setImage:[UIImage imageNamed:@"loading.png"]];
        
        self.detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 75, 75)];
        [self.detailLabel setNumberOfLines:0];
        self.detailLabel.font = [self.theme tableViewCellDetailFont];
        self.detailLabel.textColor = [self.theme tableViewCellDetailFontColor];
        [self.detailLabel setLineBreakMode:NSLineBreakByWordWrapping];

        
        [self.imgView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.detailLabel setTranslatesAutoresizingMaskIntoConstraints:NO];

        
        [self.contentView addSubview:self.imgView];
        [self.contentView addSubview:self.titleLabel];
        [self.contentView addSubview:self.detailLabel];
        
        NSDictionary *views = @{ @"imageView" : self.imgView, @"label" : self.titleLabel,@"detail":self.detailLabel};
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[imageView(75)]-[label]-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[imageView(75)]-[detail]-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[imageView(75)]" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[label]-[detail]-|" options:0 metrics:nil views:views]];
        
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
