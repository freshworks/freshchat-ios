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
    if(options){
        if ([viewController conformsToProtocol:@protocol(ConversationOptionsInterface)]){
            HLViewController <ConversationOptionsInterface> *vc
            = (HLViewController <ConversationOptionsInterface> *) viewController;
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
