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
        
        self.contentEncloser = [[UIView alloc]init];
        self.contentEncloser.translatesAutoresizingMaskIntoConstraints = NO;
    
        self.titleLabel = [[UILabel alloc] init];
        [self.titleLabel setNumberOfLines:2];
        [self.titleLabel setLineBreakMode:NSLineBreakByTruncatingTail];
        self.titleLabel.font = [self.theme tableViewCellDetailFont];
        self.titleLabel.textColor = [self.theme tableViewCellDetailFontColor];
        
        self.imgView=[[UIImageView alloc] init];
        self.imgView.backgroundColor = [UIColor greenColor];
        self.imgView.backgroundColor=[self.theme tableViewCellImageBackgroundColor];
        [self.imgView.layer setMasksToBounds:YES];
        self.imgView.contentMode = UIViewContentModeScaleAspectFit;
        
        self.detailLabel = [[UILabel alloc] init];
        [self.detailLabel setNumberOfLines:2];
        self.detailLabel.font = [self.theme tableViewCellDetailFont];
        self.detailLabel.textColor = [self.theme tableViewCellDetailFontColor];
        [self.detailLabel setLineBreakMode:NSLineBreakByTruncatingTail];

        [self.imgView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.detailLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        [self.contentView addSubview:self.contentEncloser];
        [self.contentEncloser addSubview:self.imgView];
        [self.contentEncloser addSubview:self.titleLabel];
        [self.contentEncloser addSubview:self.detailLabel];
        
        NSDictionary *views = @{ @"imageView" : self.imgView, @"title" : self.titleLabel,@"subtitle":self.detailLabel,
                                 @"contentEncloser" : self.contentEncloser };
        
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[contentEncloser]" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[contentEncloser]|" options:0 metrics:nil views:views]];
        [self.contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[title]-5-[subtitle]" options:0 metrics:nil views:views]];
        [self.contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView(50)]-[title]-|" options:0 metrics:nil views:views]];
        [self.contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageView]|" options:0 metrics:nil views:views]];
        [self.contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView]-[subtitle]-|" options:0 metrics:nil views:views]];
        
        [self addAccessoryView];
        
        [self setupTheme];
    }
    return self;
}

-(void)addAccessoryView{
    
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
