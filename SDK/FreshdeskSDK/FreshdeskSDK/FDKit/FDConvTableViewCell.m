//
//  FDConvTableViewCell.m
//  FreshdeskSDK
//
//  Created by Hrishikesh on 21/10/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDConvTableViewCell.h"

@implementation FDConvTableViewCell : FDTableViewCell

-(void)setupTheme{
    if (self) {
        self.backgroundColor     = [self.theme conversationsViewCellBackgroundColor];
        self.textLabel.textColor = [self.theme conversationsViewCellFontColor];
        CGFloat cellFontSize     = [self.theme conversationsViewCellFontSize];
        NSString *cellFontName   = [self.theme conversationsViewCellFontName];
        self.textLabel.font      = [UIFont fontWithName:cellFontName size:cellFontSize];
        self.detailTextLabel.textColor = [self.theme conversationsTimeDetailTextColor];
    }
}

@end