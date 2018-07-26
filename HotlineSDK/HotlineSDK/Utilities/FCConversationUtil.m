//
//  HLConversationUtil.m
//  HotlineSDK
//
//  Created by user on 20/12/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCConversationUtil.h"
#import "ConversationOptionsInterface.h"

@implementation FCConversationUtil

+(void) setConversationOptions:(ConversationOptions*) options andViewController: (FCViewController *) viewController{
    if(options){
        if ([viewController conformsToProtocol:@protocol(ConversationOptionsInterface)]){
            FCViewController <ConversationOptionsInterface> *vc
            = (FCViewController <ConversationOptionsInterface> *) viewController;
            [vc setConversationOptions:options];
        }
    }
}

+(BOOL) hasTags:(ConversationOptions *) options{
    if(options){
        return options.tags && options.tags.count > 0;
    }
    return NO;
}

+(BOOL) hasFilteredViewTitle:(ConversationOptions *) options{
    if(options){
        return options.filteredViewTitle && options.filteredViewTitle.length > 0;
    }
    return NO;
}

@end
