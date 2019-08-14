//
//  FCEventsHelper.h
//  FreshchatSDK
//
//  Created by Harish Kumar on 30/04/19.
//  Copyright © 2019 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FreshchatSDK.h"
#import "FCOutboundEvent.h"

NS_ASSUME_NONNULL_BEGIN

@interface FCEventsHelper : NSObject

+ (NSDictionary *) getDictionaryForParamsDict : (NSDictionary *) dict;

+ (void) postNotificationForEvent : (FCOutboundEvent *) event;

+ (NSDictionary *) getEventsDict;

@end

NS_ASSUME_NONNULL_END
