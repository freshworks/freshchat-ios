//
//  FDNotificationBanner.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 07/01/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HLChannel.h"
static CGFloat NOTIFICATION_BANNER_HEIGHT = 70;

@class FDNotificationBanner;

@protocol FDNotificationBannerDelegate <NSObject>

-(void)notificationBanner:(FDNotificationBanner *)banner bannerTapped:(id)sender;

@end

@interface FDNotificationBanner : UIView

@property (nonatomic, strong) UILabel *title;
@property (nonatomic, strong) UILabel *message;
@property (nonatomic, strong) UIImageView *imgView;
@property (nonatomic, strong, readonly) HLChannel *currentChannel;

@property (nonatomic, weak) id<FDNotificationBannerDelegate> delegate;

+(instancetype)sharedInstance;
-(void)displayBannerWithChannel:(HLChannel *)channel;
-(void)dismiss;

@end