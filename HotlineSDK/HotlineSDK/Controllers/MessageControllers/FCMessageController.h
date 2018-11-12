//
//  FDMessageController.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 27/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FCInputToolbarView.h"
#import "FCChannels.h"
#import "FCJWTViewController.h"
#import "FCYesNoPromptView.h"
#import "FCCSATView.h"
#import "ConversationOptionsInterface.h"

#define FC_PROFILEIMAGE_DIMENSION 40.0

enum ResponseTimeType {
    CURRENT_AVG  = 1,
    LAST_WEEK_AVG = 2
};

@interface FCMessageController : FCJWTViewController <FDInputToolbarViewDelegate, UIGestureRecognizerDelegate, FCYesNoPromptViewDelegate, HLCSATViewDelegate, ConversationOptionsInterface>

-(BOOL)isModal;

-(instancetype)initWithChannelID:(NSNumber *)channelID andPresentModally:(BOOL)isModal;

-(instancetype)initWithChannelID:(NSNumber *)channelID andPresentModally:(BOOL)isModal fromNotification:(BOOL) fromNotification;

@end
