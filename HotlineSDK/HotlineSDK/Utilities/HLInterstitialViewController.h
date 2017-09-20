//
//  HLViewRedirector.h
//  HotlineSDK
//
//  Created by user on 16/01/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FAQOptionsInterface.h"
#import "ConversationOptionsInterface.h"
#import "HLConversationUtil.h"
#import "HLViewController.h"
#import "Hotline.h"

@interface HLInterstitialViewController : UIViewController

@property (nonatomic, strong) id delegate;

-(instancetype) initViewControllerWithOptions:(HotlineOptions *) options andIsEmbed:(BOOL) isEmbed;

@end
