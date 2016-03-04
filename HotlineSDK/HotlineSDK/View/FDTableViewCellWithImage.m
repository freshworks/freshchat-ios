//
//  FDCategoryTableViewCell.m
//  HotlineSDK
//
//  Created by user on 27/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDTableViewCellWithImage.h"
#import "FDSecureStore.h"

@interface FDTableViewCellWithImage ()

@property (strong, nonatomic) HLTheme *theme;

@end

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
        
        self.imgView=[[FDImageView alloc] init];
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
        
        FDSecureStore *store = [FDSecureStore sharedInstance];
        BOOL showChannelThumbnail = [store boolValueForKey:HOTLINE_DEFAULTS_SHOW_CHANNEL_THUMBNAIL];
        
        [self.contentView addSubview:self.contentEncloser];
        [self.contentEncloser addSubview:self.imgView];
        [self.contentEncloser addSubview:self.titleLabel];
        [self.contentEncloser addSubview:self.detailLabel];
        
        NSDictionary *views = @{ @"imageView" : self.imgView, @"title" : self.titleLabel,@"subtitle":self.detailLabel,
                                 @"contentEncloser" : self.contentEncloser };
        
        [self.contentEncloser addConstraint:[NSLayoutConstraint constraintWithItem:self.imgView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentEncloser attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[contentEncloser]" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[contentEncloser]|" options:0 metrics:nil views:views]];
        [self.contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[title][subtitle]-2-|" options:0 metrics:nil views:views]];
        if(showChannelThumbnail){
            [self.contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView(50)]-[title]|" options:0 metrics:nil views:views]];
            [self.contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[imageView(50)]" options:0 metrics:nil views:views]];
            [self.contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView]-[subtitle]|" options:0 metrics:nil views:views]];
        }
        else{
            [self.contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[title]|" options:0 metrics:nil views:views]];
            [self.contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[subtitle]|" options:0 metrics:nil views:views]];
        }
        [self addAccessoryView];
        [self setupTheme];
    }
    return self;
}

-(void)addAccessoryView{
    NSLog(@"WARNING: Unimplemented method. %@ should implement addAccessoryView" , self.class);
}

-(void)setupTheme{
    if (self) {
        self.backgroundColor     = [self.theme tableViewCellBackgroundColor];
        self.titleLabel.textColor = [self.theme tableViewCellFontColor];
        self.titleLabel.font      = [self.theme tableViewCellFont];
        self.detailLabel.textColor = [self.theme tableViewCellDetailFontColor];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
}

-(void)prepareForReuse{
    [super prepareForReuse];
    self.imgView.image = [[HLTheme sharedInstance] getImageWithKey:@"FAQLoadingIcon"];
}

@end
