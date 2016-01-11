//
//  FDNotificationBanner.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 07/01/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HLChannel.h"

@interface FDNotificationBanner : UIView

@property (nonatomic, strong) UILabel *title;
@property (nonatomic, strong) UILabel *message;
@property (nonatomic, strong) UIImageView *imgView;

+ (instancetype)sharedInstance;

-(void)displayBannerWithChannel:(HLChannel *)channel;
-(void)dismiss;

@end