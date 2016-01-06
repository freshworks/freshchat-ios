//
//  WebServices.h
//  Konotor
//
//  Created by Vignesh G on 12/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KonotorMessage.h"

#define MESSAGE_NOT_UPLOADED 0
#define MESSAGE_UPLOADING 1
#define MESSAGE_UPLOADED 2

#define PROPERTY_NOT_UPLOADED 0
#define PROPERTY_UPLOADING 1
#define PROPERTY_UPLOADED 2

#define EVENT_NOT_UPLOADED 0
#define EVENT_UPLOADING 1
#define EVENT_UPLOADED 2

@interface KonotorWebServices : NSObject

+(void) uploadMessage:(KonotorMessage *)pMessage toConversation:(KonotorConversation *)conversation onChannel:(HLChannel *)channel;
+(void) UpdateAppVersion:(NSString *) appVersion;
+(void) UpdateSdkVersion: (NSString *) sdkVersion;

@end