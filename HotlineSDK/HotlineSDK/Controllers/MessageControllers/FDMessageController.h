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
#import "FDYesNoPromptView.h"
#import "HLCSATView.h"
#import "ConversationOptionsInterface.h"

@interface FDMessageController : HLViewController <FDInputToolbarViewDelegate, UIGestureRecognizerDelegate, HLYesNoPromptViewDelegate, HLCSATViewDelegate, ConversationOptionsInterface>

-(BOOL)isModal;

-(instancetype)initWithChannelID:(NSNumber *)channelID andPresentModally:(BOOL)isModal;

@end
