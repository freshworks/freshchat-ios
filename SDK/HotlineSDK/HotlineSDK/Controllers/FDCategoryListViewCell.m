//
//  FDCategoryListViewCell.m
//  Hotline
//
//  Created by user on 29/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDCategoryListViewCell.h"

@implementation FDCategoryListViewCell

-(void)addAccessoryView{
    UIImageView *accessoryView = [[UIImageView alloc] init];
    // TODO : Should be read from a Theme. 
    accessoryView.image = [HLTheme getImageFromMHBundleWithName:@"rightArrow.png"];
    accessoryView.translatesAutoresizingMaskIntoConstraints=NO;
    [self.contentView addSubview:accessoryView];
    NSDictionary *views = @{@"contentEncloser" : self.contentEncloser,@"accessoryView" : accessoryView};
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[contentEncloser]-10-[accessoryView(6)]-10-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
}

@end