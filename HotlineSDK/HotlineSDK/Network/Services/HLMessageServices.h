//
//  HLMessageServices.h
//  HotlineSDK
//
//  Created by user on 03/11/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLChannel.h"


@interface HLMessageServices : NSObject

+(void)downloadAllMessages:(void(^)(NSError *error))handler;

/* fetches channel list, updates existing channels including hidden channels */
-(NSURLSessionDataTask *)fetchAllChannels:(void (^)(NSArray<HLChannel *> *channels, NSError *error))handler;

+(void)uploadMessage:(KonotorMessage *)pMessage toConversation:(KonotorConversation *)conversation onChannel:(HLChannel *)channel;

+(void)markMarketingMessageAsClicked:(NSNumber *)marketingId;

+(void)markMarketingMessageAsRead:(KonotorMessage *)message context:(NSManagedObjectContext *)context;

@end