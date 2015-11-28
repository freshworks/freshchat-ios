//
//  WebServices.h
//  Konotor
//
//  Created by Vignesh G on 12/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KonotorMessage.h"
#import "KonotorCustomProperties.h"
#import "KonotorShareMessageEvent.h"

@interface KonotorWebServices : NSObject

+(void) uploadMessage:(KonotorMessage *)pMessage toConversation:(KonotorConversation *)conversation onChannel:(HLChannel *)channel;
+(void) AddPushDeviceToken: (NSString *) deviceToken;
+(void) DAUCall;
+(void) UpdateUserPropertiesWithDictionary:(NSDictionary *) dict withProperty:(KonotorCustomProperty *)property;
+(void) sendShareMessageEvent:(KonotorShareMessageEvent *)shareEvent;
+(void) UpdateAppVersion:(NSString *) appVersion;
+(void) UpdateSdkVersion: (NSString *) sdkVersion;

@end