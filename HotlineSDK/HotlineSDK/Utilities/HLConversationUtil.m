//
//  HLConversationUtil.m
//  HotlineSDK
//
//  Created by user on 20/12/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLConversationUtil.h"
#import "ConversationOptionsInterface.h"

@implementation HLConversationUtil

+(void) setConversationOptions:(ConversationOptions*) options andViewController: (HLViewController *) viewController{
    if ([viewController conformsToProtocol:@protocol(ConversationOptionsInterface)]){
        HLViewController <ConversationOptionsInterface> *vc
        = (HLViewController <ConversationOptionsInterface> *) viewController;
        [vc setConversationOptions:options];
    }
}

@end
