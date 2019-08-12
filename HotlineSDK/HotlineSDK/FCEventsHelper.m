//
//  FCEventsHelper.m
//  FreshchatSDK
//
//  Created by Harish Kumar on 30/04/19.
//  Copyright © 2019 Freshdesk. All rights reserved.
//

#import "FCEventsHelper.h"
#import "FreshchatSDK.h"
#import "FCLocalNotification.h"

@implementation FCEventsHelper


+ (NSDictionary *) getDictionaryForParamsDict : (NSDictionary *) dict {
    NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
    for(id key in dict){
        [newDict setObject:[dict objectForKey:key] forKey:[[self getEventsDict] objectForKey:key]];
    }
    return newDict;
}

+ (NSDictionary *) getEventsDict
{
    return @{
             @(FCPropertyFAQCategoryID)     : @"FCPropertyFAQCategoryID",
             @(FCPropertyFAQCategoryName)   : @"FCPropertyFAQCategoryName",
             @(FCPropertyFAQID)             : @"FCPropertyFAQID",
             @(FCPropertyFAQTitle)          : @"FCPropertyFAQTitle",
             @(FCPropertySearchKey)         : @"FCPropertySearchKey",
             @(FCPropertySearchFAQCount)    : @"FCPropertySearchFAQCount",
             @(FCPropertyChannelID)         : @"FCPropertyChannelID",
             @(FCPropertyChannelName)       : @"FCPropertyChannelName",
             @(FCPropertyConversationID)    : @"FCPropertyConversationID",
             @(FCPropertyIsHelpful)         : @"FCPropertyIsHelpful",
             @(FCPropertyIsRelevant)        : @"FCPropertyIsRelevant",
             @(FCPropertyInputTags)         : @"FCPropertyInputTags",
             @(FCPropertyRating)            : @"FCPropertyRating",
             @(FCPropertyResolutionStatus)  : @"FCPropertyResolutionStatus",
             @(FCPropertyComment)           : @"FCPropertyComment",
             @(FCPropertyURL)               : @"FCPropertyURL"
             };
}

+ (void) postNotificationForEvent : (FCOutboundEvent *) event {
    FreshchatEvent *fcEvent = [[FreshchatEvent alloc] init];
    fcEvent.name = event.eventName;
    fcEvent.properties = event.properties;
    NSDictionary *dict = [NSDictionary dictionaryWithObject:fcEvent forKey:@"Event"];
    [FCLocalNotification post:FRESHCHAT_ACTION_USER_ACTIONS info:dict];
}

@end
