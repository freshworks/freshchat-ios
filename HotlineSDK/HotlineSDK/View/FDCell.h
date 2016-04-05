//
//  FDCell.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 30/03/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDLabel.h"
#import "FDImageView.h"
#import "FDBadgeView.h"

@interface FDCell : UITableViewCell

@property (strong, nonatomic) FDLabel *titleLabel;
@property (strong, nonatomic) FDLabel *detailLabel;
@property (strong, nonatomic) UIView *contentEncloser;
@property (strong, nonatomic) FDImageView *imgView;
@property (strong, nonatomic) FDBadgeView *badgeView;
@property (strong, nonatomic) UILabel *lastUpdatedLabel;
@property (strong, nonatomic) NSLayoutConstraint *encloserHeightConstraint;
@property (strong, nonatomic) NSLayoutConstraint *detailLableRightConstraint;
@property (assign, nonatomic) BOOL isChannelCell;

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier isChannelCell:(BOOL)isChannelCell;

+(UIImage *)generateImageForLabel:(NSString *)labelText;

-(void)adjustPadding;

@end
