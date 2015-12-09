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

//+(BOOL) CreateUser: (NSString *) UserID;
//+(BOOL) CreateUserOnServerIfNotPresent:(NSString *) UserID andPerformSelectorIfSuccessful:(SEL)aSelector withObject:(id) object;

/*+(BOOL) CreateUserOnServerIfNotPresentandPerformSelectorIfSuccessful:(SEL)SuccessSelector withObject:(id) successObject withSuccessParameter:(id) successParameter
                                                           ifFailure:(SEL)failureSelector withObject: (id) failureObject withFailureParameter:(id) failureParameter;*/

+(void) UploadMessage : (KonotorMessage *)pMessage toConversation: (KonotorConversation *) conversationToUploadTo;
+(void) AddPushDeviceToken: (NSString *) deviceToken;
+(void) DAUCall;
+(void) UpdateUserPropertiesWithDictionary:(NSDictionary *) dict withProperty:(KonotorCustomProperty *)property;
+(void) sendShareMessageEvent:(KonotorShareMessageEvent *)shareEvent;
+(void) UpdateAppVersion:(NSString *) appVersion;
+(void) UpdateSdkVersion: (NSString *) sdkVersion;

@end
