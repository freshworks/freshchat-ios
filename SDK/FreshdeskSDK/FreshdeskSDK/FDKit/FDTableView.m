//
//  FDTableView.m
//  FreshdeskSDK
//
//  Created by Aravinth on 19/07/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDTableView.h"
#import "FDTheme.h"

@interface FDTableView ()
@property (strong, nonatomic) FDTheme *theme;
@end

@implementation FDTableView

-(FDTheme *)theme{
    if(!_theme){ _theme = [FDTheme sharedInstance]; }
    return _theme;
}

-(id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style{
    self = [super initWithFrame:frame style:style];
    if (self) {
        self.backgroundColor = [self.theme backgroundColorSDK];
        self.separatorColor = [self.theme tableViewCellSeparatorColor];
    }
    return self;
}

@end
