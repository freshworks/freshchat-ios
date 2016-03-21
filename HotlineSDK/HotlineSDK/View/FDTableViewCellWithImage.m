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
@property (strong, nonatomic) NSLayoutConstraint *titleBottomConstraint;
@property (strong, nonatomic) NSLayoutConstraint *detailLabelHeightConstraint;

@end

@implementation FDTableViewCellWithImage


-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.theme = [HLTheme sharedInstance];
        
        self.contentEncloser = [[UIView alloc]init];
        self.contentEncloser.translatesAutoresizingMaskIntoConstraints = NO;
    
        self.titleLabel = [[FDLabel alloc] init];
        [self.titleLabel setNumberOfLines:0];
        [self.titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
        
        self.imgView=[[FDImageView alloc] init];
        [self.imgView.layer setMasksToBounds:YES];
        self.imgView.contentMode = UIViewContentModeScaleAspectFit;
        
        self.detailLabel = [[FDLabel alloc] init];
        [self.detailLabel setNumberOfLines:2];
        [self.detailLabel setLineBreakMode:NSLineBreakByWordWrapping];

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
        
        self.titleBottomConstraint = [NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.imgView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
        
        
        self.detailLabelHeightConstraint = [NSLayoutConstraint constraintWithItem:self.detailLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:0];
        
        [self.contentEncloser addConstraint:self.detailLabelHeightConstraint];
        [self.contentEncloser addConstraint:self.titleBottomConstraint];
        
        if(showChannelThumbnail){
            [self.contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView(50)]-[title]|" options:0 metrics:nil views:views]];
            [self.contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[imageView(50)]" options:0 metrics:nil views:views]];
            [self.contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView]-[subtitle]" options:0 metrics:nil views:views]];
        }
        else{
            [self.contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[title]|" options:0 metrics:nil views:views]];
            [self.contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[subtitle]|" options:0 metrics:nil views:views]];
        }
        
        [self.contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[title][subtitle]" options:0 metrics:nil  views:views]];

        
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
        self.titleLabel.textColor = [self.theme tableViewCellTitleFontColor];
        self.titleLabel.font      = [self.theme tableViewCellTitleFont];
        self.detailLabel.textColor = [self.theme tableViewCellDetailFontColor];
        self.detailLabel.font = [self.theme tableViewCellDetailFont];
    }
}

-(void)layoutSubviews{
    [super layoutSubviews];

    CGFloat titleHeight = self.titleLabel.frame.size.height;
    CGFloat detailHeight = self.detailLabel.frame.size.height;

    CGFloat MAX_HEIGHT = 30;
    
    NSInteger PREFERRED_PADDING = 5;
    
    self.detailLabelHeightConstraint.constant = self.detailLabel.intrinsicContentSize.height;
    
    if (titleHeight !=0 && detailHeight !=0) {
        
        if (titleHeight > MAX_HEIGHT && detailHeight > MAX_HEIGHT) {
            self.detailLabelHeightConstraint.constant = detailHeight/2;
            self.titleBottomConstraint.constant = PREFERRED_PADDING;
        }else{
            
            if (fabs(titleHeight - detailHeight) > PREFERRED_PADDING) {
                if (titleHeight > detailHeight) {
                    self.titleBottomConstraint.constant = PREFERRED_PADDING;
                }else{
                    self.titleBottomConstraint.constant = -PREFERRED_PADDING;
                }
            }
        }
    }
    
    [self layoutIfNeeded];
    
}

-(void)prepareForReuse{
    [super prepareForReuse];
    self.imgView.image = [[HLTheme sharedInstance] getImageWithKey:@"FAQLoadingIcon"];
}

- (CGFloat)getLabelHeight:(UILabel*)label{
    CGSize constraint = CGSizeMake(label.frame.size.width, 20000.0f);
    CGSize size;
    
    NSStringDrawingContext *context = [[NSStringDrawingContext alloc] init];
    CGSize boundingBox = [label.text boundingRectWithSize:constraint
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                               attributes:@{NSFontAttributeName:label.font}
                                                  context:context].size;
    
    size = CGSizeMake(ceil(boundingBox.width), ceil(boundingBox.height));
    
    return size.height;
}


@end
