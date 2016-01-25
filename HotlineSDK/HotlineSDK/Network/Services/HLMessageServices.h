//
//  HLMessageServices.h
//  HotlineSDK
//
//  Created by user on 03/11/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLChannel.h"

#define MESSAGE_NOT_UPLOADED 0
#define MESSAGE_UPLOADING 1
#define MESSAGE_UPLOADED 2

#define PROPERTY_NOT_UPLOADED 0
#define PROPERTY_UPLOADING 1
#define PROPERTY_UPLOADED 2

#define EVENT_NOT_UPLOADED 0
#define EVENT_UPLOADING 1
#define EVENT_UPLOADED 2

@interface HLMessageServices : NSObject

+(void)downloadAllMessages:(void(^)(NSError *error))handler;

/* fetches channel list, updates existing channels including hidden channels */
-(NSURLSessionDataTask *)fetchAllChannels:(void (^)(NSArray<HLChannel *> *channels, NSError *error))handler;

+(void)uploadMessage:(KonotorMessage *)pMessage toConversation:(KonotorConversation *)conversation onChannel:(HLChannel *)channel;

+(void)markMarketingMessageAsClicked:(NSNumber *)marketingId;

@end