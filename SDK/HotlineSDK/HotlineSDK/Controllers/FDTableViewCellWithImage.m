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
    
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(57.5, 77, 61, 23.5)];
        [self.titleLabel setNumberOfLines:2];
        [self.titleLabel setLineBreakMode:NSLineBreakByTruncatingTail];
        self.titleLabel.font = [self.theme tableViewCellDetailFont];
        self.titleLabel.textColor = [self.theme tableViewCellDetailFontColor];
        
        self.imgView=[[UIImageView alloc] initWithFrame:CGRectMake(21, 86, 13.9, 20.9)];
        self.imgView.backgroundColor=[self.theme tableViewCellImageBackgroundColor];
        [self.imgView.layer setMasksToBounds:YES];
        self.imgView.contentMode = UIViewContentModeScaleAspectFit;
        
        self.detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(57, 98.5, 231.5, 16.9)];
        [self.detailLabel setNumberOfLines:2];
        self.detailLabel.font = [self.theme tableViewCellDetailFont];
        self.detailLabel.textColor = [self.theme tableViewCellDetailFontColor];
        [self.detailLabel setLineBreakMode:NSLineBreakByTruncatingTail];

        [self.imgView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.detailLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        [self.contentView addSubview:self.imgView];
        [self.contentView addSubview:self.titleLabel];
        [self.contentView addSubview:self.detailLabel];
        
        NSDictionary *views = @{ @"imageView" : self.imgView, @"title" : self.titleLabel,@"subtitle":self.detailLabel};
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[imageView(40)]-[title]-|" options:NSLayoutFormatAlignAllTop metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[imageView]-[subtitle]-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[imageView(40)]" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[title]-10-[subtitle]" options:0 metrics:nil views:views]];
        
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
