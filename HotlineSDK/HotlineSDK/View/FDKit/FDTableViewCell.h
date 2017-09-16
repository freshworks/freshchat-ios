//
//  FDTableViewCell.h
//  FreshdeskSDK
//
//  Created by Aravinth on 19/07/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FCTheme.h"

@interface FDTableViewCell : UITableViewCell

@property (strong, nonatomic) FCTheme *theme;

-(void)setupTheme;

@end
