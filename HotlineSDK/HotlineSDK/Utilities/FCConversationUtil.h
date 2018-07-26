//
//  HLConversationUtil.h
//  HotlineSDK
//
//  Created by user on 20/12/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//
#ifndef ConversationUtil_h
#define ConversationUtil_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FCViewController.h"
#import "FreshchatSDK.h"


@interface FCConversationUtil : NSObject

+(void) setConversationOptions:(ConversationOptions*) options andViewController: (FCViewController *) viewController;
+(BOOL) hasTags:(ConversationOptions *) options;
+(BOOL) hasFilteredViewTitle:(ConversationOptions *) options;
@end

#endif
