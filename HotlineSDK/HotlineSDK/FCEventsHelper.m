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
#import "FCSecureStore.h"
#import "FCUtilities.h"
#import "FCUserDefaults.h"
#import "FCRemoteConfig.h"
#import "FCUserUtil.h"
#import "FCStringUtil.h"
#import "FCMacros.h"
#import "FCEventsConstants.h"

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
    NSDictionary *dict = [NSDictionary dictionaryWithObject:fcEvent forKey:@"event"];
    [FCLocalNotification post:FRESHCHAT_EVENTS info:dict];
}


+ (BOOL) canUploadEventWithCount{
    NSDate *eventsLastFetchDate = [[FCSecureStore sharedInstance] objectForKey : FRESHCHAT_DEFAULTS_EVENTS_LAST_RECORDED_TIME];
    int dailyEventsCount = (int)[[FCSecureStore sharedInstance] intValueForKey : FRESHCHAT_DEFAULTS_EVENTS_DAILY_COUNTER];
    if (!eventsLastFetchDate || ![FCUtilities isTodaySameAsDate:eventsLastFetchDate]){
        [self updateEventsLastRecTimeWithCount:1];
        return TRUE;
    }else if(dailyEventsCount < [[FCRemoteConfig sharedInstance]eventsConfig].maxAllowedEventsPerDay){
        dailyEventsCount ++;
        [self updateEventsLastRecTimeWithCount:dailyEventsCount];
        return TRUE;
    }
    ALog(@"Event discarded. User events have reached the daily limit of %d",[FCRemoteConfig sharedInstance].eventsConfig.maxAllowedEventsPerDay);
    return FALSE;
}

+ (void) removeEventsIdentifier {
    [FCUserDefaults removeObjectForKey: FRESHCHAT_DEFAULTS_EVENTS_LAST_RECORDED_TIME];
    [FCUserDefaults removeObjectForKey: FRESHCHAT_DEFAULTS_EVENTS_DAILY_COUNTER];
}

+ (NSDictionary *) getValidatedEventsProps : (NSDictionary *) properties {
    NSMutableDictionary *newProps = [NSMutableDictionary new];
    int maxPropsCount = [FCRemoteConfig sharedInstance].eventsConfig.maxAllowedPropertiesPerEvent;
    if (properties.count == 0) return newProps;
    if (properties.count > maxPropsCount){
        newProps[FRESHCHAT_INVALID_PROPERTY] = [NSString stringWithFormat:
                                               FRESHCHAT_ERROR_PROPERTY_LIMIT_EXCEEDED,maxPropsCount];
    }
    NSUInteger index = 0;
    for(NSString* key in properties) {
        if (index >= maxPropsCount){
            break;
        }
        if ([FCStringUtil isEmptyString:key]) {
            newProps[FRESHCHAT_INVALID_PROPERTY] = FRESHCHAT_ERROR_PROPERTY_NAME_EMPTY;
        }
        else if (![self hasValidEventPropertyNameLength:key]){
            newProps[FRESHCHAT_INVALID_PROPERTY] = [NSString stringWithFormat:FRESHCHAT_ERROR_PROPERTY_NAME_EXCEEDS_LIMIT,
                                                   [key substringToIndex: [FCRemoteConfig sharedInstance].eventsConfig.maxCharsPerEventPropertyName]];
        }
        else if (![self hasValidKeyValueType:properties[key]]){
            newProps[FRESHCHAT_INVALID_PROPERTY] = [NSString stringWithFormat:FRESHCHAT_ERROR_PROPERTY_VALUE_UNSUPPORTED, key];
        }
        else if ([FCStringUtil isEmptyString:[NSString stringWithFormat:@"%@", properties[key]]]) {
            newProps[FRESHCHAT_INVALID_PROPERTY] = [NSString stringWithFormat:FRESHCHAT_ERROR_PROPERTY_VALUE_EMPTY,key];
        }
        else if (![self hasValidPropertyKeyValueLength:properties[key]]){
            newProps[FRESHCHAT_INVALID_PROPERTY] = [NSString stringWithFormat:FRESHCHAT_ERROR_PROPERTY_VALUE_EXCEEDS_LIMIT, key];
        }
        else{
            newProps[key] = properties[key];
        }
        index++;
    }
    return newProps;
}

+(BOOL) hasValidEventNameLength: (NSString *) key {
    return ([FCStringUtil isNotEmptyString:key] && ([key length] <= [FCRemoteConfig sharedInstance].eventsConfig.maxCharsPerEventName)) ;
}

+(BOOL) hasValidEventPropertyNameLength: (NSString *) key {
    return ([FCStringUtil isNotEmptyString:key] && ([key length] <= [FCRemoteConfig sharedInstance].eventsConfig.maxCharsPerEventPropertyName)) ;
}

+(BOOL) hasValidPropertyKeyValueLength: (NSObject *) keyValue {
    keyValue = [NSString stringWithFormat:@"%@", keyValue];
    return (( trimString([FCStringUtil getStringValue : keyValue]).length > 0)
            && (([FCStringUtil getStringValue : keyValue].length) <= [FCRemoteConfig sharedInstance].eventsConfig.maxCharsPerEventPropertyValue));
}

+(BOOL) hasValidKeyValueType : (NSObject *) keyValue {
    return ([keyValue isKindOfClass:[NSString class]] || [keyValue isKindOfClass:[NSNumber class]]);
}

+ (void) updateEventsLastRecTimeWithCount : (int) count {
    [[FCSecureStore sharedInstance] setObject:[NSDate date] forKey : FRESHCHAT_DEFAULTS_EVENTS_LAST_RECORDED_TIME];
    [[FCSecureStore sharedInstance] setIntValue:(NSInteger)count forKey: FRESHCHAT_DEFAULTS_EVENTS_DAILY_COUNTER];
}


@end
