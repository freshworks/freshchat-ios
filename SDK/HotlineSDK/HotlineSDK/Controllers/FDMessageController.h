//
//  FDMessageController.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 27/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDInputToolbarView.h"
#import "HLChannel.h"

@interface FDMessageController : UIViewController <FDInputToolbarViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong, readonly) HLChannel *channel;

-(BOOL)isModal;

-(instancetype)initWithChannel:(HLChannel *)channel andPresentModally:(BOOL)isModal;

@end