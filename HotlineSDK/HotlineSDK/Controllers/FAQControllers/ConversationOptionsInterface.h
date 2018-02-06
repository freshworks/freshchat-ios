//
//  ConversationOptionsInterface.h
//  HotlineSDK
//
//  Created by user on 20/12/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FreshchatSDK.h"

@protocol ConversationOptionsInterface <NSObject>

@required

-(void)setConversationOptions:(ConversationOptions *)options;

@end
