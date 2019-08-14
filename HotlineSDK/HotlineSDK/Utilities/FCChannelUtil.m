//
//  FCChannelUtil.m
//  FreshchatSDK
//
//  Created by Sanjith Kanagavel on 20/11/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import "FCChannelUtil.h"
#import "FCControllerUtils.h"

@interface ConversationOptions()

-(void) filterByChannelID:(NSNumber *) channelID withTitle:(NSString *)title;

@end

@implementation FCChannelUtil : NSObject

+(void) launchChannelWithTags:(NSArray *)tags withTitle:(NSString *)title withNavigationCtlr:(UIViewController *)viewController  {
    ConversationOptions *convOptions = [[ConversationOptions alloc] init];
    [convOptions filterByTags:tags withTitle:title];
    [[Freshchat sharedInstance] showConversations:viewController withOptions:convOptions];
}

+(void) launchChannelWithId:(NSNumber *)channelID  withTitle:(NSString *)title withNavigationCtlr:(UIViewController *)viewController {
    ConversationOptions *convOptions = [[ConversationOptions alloc] init];
    [convOptions filterByChannelID:channelID withTitle:title];
    [[Freshchat sharedInstance] showConversations:viewController withOptions:convOptions];
}

@end
