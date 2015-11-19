//
//  FDCategoryListViewCell.m
//  Hotline
//
//  Created by user on 29/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDCategoryListViewCell.h"

@implementation FDCategoryListViewCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        for (id view in [self.subviews[0] subviews]) {
            if ([view isKindOfClass:[UIButton class]]) {
                UIButton *accessoryButton = (UIButton *)view;
                accessoryButton.backgroundColor = nil;
            }
        }
    }
    return self;
}

@end
