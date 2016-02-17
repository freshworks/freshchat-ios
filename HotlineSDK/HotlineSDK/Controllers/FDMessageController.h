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
#import "HLViewController.h"

@interface FDMessageController : HLViewController <FDInputToolbarViewDelegate, UIGestureRecognizerDelegate>

-(BOOL)isModal;

-(instancetype)initWithChannel:(HLChannel *)channel andPresentModally:(BOOL)isModal;

@end