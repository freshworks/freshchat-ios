//
//  HLNotificationHandler.h
//  HotlineSDK
//
//  Created by Harish Kumar on 05/04/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FDNotificationBanner.h"

@interface HLNotificationHandler : NSObject<FDNotificationBannerDelegate>

- (void) handleNotificationBanner :(HLChannel *)channel withMessage:(NSString *)message andState:(UIApplicationState)state;
-(void) showActiveStateNotificationBanner :(HLChannel *)channel withMessage:(NSString *)message;

@end
