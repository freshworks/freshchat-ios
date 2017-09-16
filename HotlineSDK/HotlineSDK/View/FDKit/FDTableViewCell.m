//
//  FDTableViewCell.m
//  FreshdeskSDK
//
//  Created by Aravinth on 19/07/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDTableViewCell.h"

@interface FDTableViewCell ()
@end

@implementation FDTableViewCell

-(FCTheme *)theme{
    if(!_theme){
        _theme = [FCTheme sharedInstance];
    }
    return _theme;
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        for (id view in [self.subviews[0] subviews]) {
            if ([view isKindOfClass:[UIButton class]]) {
                UIButton *accessoryButton = (UIButton *)view;
                accessoryButton.backgroundColor = nil;
            }
        }
        [self setupTheme];
    }
    return self;
}

-(void)setupTheme{
     if (self) {
         self.backgroundColor     = [self.theme tableViewCellBackgroundColor];
     }
}

- (UIEdgeInsets)layoutMargins {
    return UIEdgeInsetsZero;
}

@end
