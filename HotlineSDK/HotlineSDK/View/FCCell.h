//
//  FDCell.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 30/03/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FCLabel.h"
#import "FCBadgeView.h"

@interface FCCell : UITableViewCell

@property (strong, nonatomic) FCLabel *titleLabel;
@property (strong, nonatomic) FCLabel *detailLabel;
@property (strong, nonatomic) UIView *contentEncloser;
@property (strong, nonatomic) UIImageView *imgView;
@property (strong, nonatomic) FCBadgeView *badgeView;
@property (strong, nonatomic) UILabel *lastUpdatedLabel;
@property (strong, nonatomic) NSLayoutConstraint *encloserHeightConstraint;
@property (strong, nonatomic) NSLayoutConstraint *detailLableRightConstraint;
@property (strong, nonatomic) NSLayoutConstraint *lastUpdatedTimeWidthConstraint;
@property (strong, nonatomic) UIView *rightArrowImageView;
@property (assign, nonatomic) BOOL isChannelCell;

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier isChannelCell:(BOOL)isChannelCell;

-(void)adjustPadding;

@end
