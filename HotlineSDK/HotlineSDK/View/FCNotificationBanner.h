//
//  FDNotificationBanner.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 07/01/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FCChannels.h"
static CGFloat NOTIFICATION_BANNER_HEIGHT = 70;

@class FCNotificationBanner;

@protocol FDNotificationBannerDelegate <NSObject>

-(void)notificationBanner:(FCNotificationBanner *)banner bannerTapped:(id)sender;

@end

@interface FCNotificationBanner : UIView

@property (nonatomic, strong, readonly) FCChannels *currentChannel;

@property (nonatomic, weak) id<FDNotificationBannerDelegate> delegate;

+(instancetype)sharedInstance;
-(void)displayBannerWithChannel:(FCChannels *)channel;
-(void)setMessage:(NSString *)message;

@end
