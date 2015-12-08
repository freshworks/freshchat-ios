//
//  FDChannelListViewCell.h
//  HotlineSDK
//
//  Created by user on 29/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDTableViewCellWithImage.h"
#import "FDBadgeView.h"
#import "FDButton.h"

@interface FDChannelListViewCell : FDTableViewCellWithImage

@property (nonatomic,strong) FDBadgeView *badgeView;
@property (nonatomic,strong) UILabel *lastUpdatedLabel;

+(UIImage *)generateImageForLabel:(NSString *)labelText;

@end
