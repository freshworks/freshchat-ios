//
//  HLMessageServices.h
//  HotlineSDK
//
//  Created by user on 03/11/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLChannel.h"

enum MessageFetchType{
    OffScreenPollFetch,
    OnscreenPollFetch,
    InitFetch,
    ScreenLaunchFetch,
    FetchAll,
    FetchMessages,
    DefaultFetch
};

enum MessageRequestSource {
    Restore                     = 1,  // Not used
    Init                        = 2,
    ChannelList                 = 3,
    ChatScreen                  = 4,
    UnreadCount                 = 5,
    Notification                = 6,
    MissingConversation         = 7, // Not used
    OnScreenPollWithToken       = 11,
    OnScreenPollWithoutToken    = 12,
    OffScreenPoll               = 13
};

@interface HLMessageServices : NSObject

+(void)fetchChannelsAndMessagesWithFetchType:(enum MessageFetchType) priority
                                     source :(enum MessageRequestSource ) requestSource
                                  andHandler:(void (^)(NSError *))handler;

+(NSURLSessionDataTask *)fetchAllChannels:(void (^)(NSArray<HLChannel *> *channels, NSError *error))handler;

+(void)fetchMessagesForSrc:(enum MessageRequestSource) requestSource andCompletion:(void(^)(NSError *error))handler;

+(void)uploadMessage:(KonotorMessage *)pMessage toConversation:(KonotorConversation *)conversation onChannel:(HLChannel *)channel;

+(void)markMarketingMessageAsClicked:(NSNumber *)marketingId;

+(void)markMarketingMessageAsRead:(KonotorMessage *)message context:(NSManagedObjectContext *)context;

+(void)postCSATWithID:(NSManagedObjectID *)csatObjectID completion:(void (^)(NSError *))handler;

+(void)uploadUnuploadedCSAT;

@end
