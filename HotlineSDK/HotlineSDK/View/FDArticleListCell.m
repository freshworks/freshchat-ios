//
//  FDArticleListCell.m
//  HotlineSDK
//
//  Created by Harish Kumar on 02/02/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FDArticleListCell.h"
#import "HLTheme.h"
#import "FDAutolayoutHelper.h"

@interface FDArticleListCell ()

@property (strong, nonatomic) HLTheme *theme;

@end

@implementation FDArticleListCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.theme = [HLTheme sharedInstance];
        
        self.articleText = [[UILabel alloc] init];
        [self.articleText setNumberOfLines:3];
        [self.articleText setLineBreakMode:NSLineBreakByTruncatingTail];
        [self.articleText setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        UIImageView *accessoryView = [[UIImageView alloc] init];
        accessoryView.image = [self.theme getImageWithKey:IMAGE_TABLEVIEW_ACCESSORY_ICON];
        accessoryView.translatesAutoresizingMaskIntoConstraints=NO;

        [self.contentView addSubview:accessoryView];
        [self.contentView addSubview:self.articleText];
        
        NSDictionary *views = @{@"title" : self.articleText, @"accessoryView":accessoryView};
        
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[title]|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[title]-[accessoryView(6)]-10-|" options:0 metrics:nil views:views]];
        [FDAutolayoutHelper centerY:accessoryView onView:self.contentView];
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
        self.articleText.textColor = [self.theme articleListFontColor];
        self.articleText.font = [self.theme articleListFont];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
}

-(void)prepareForReuse{
    [super prepareForReuse];
}

@end