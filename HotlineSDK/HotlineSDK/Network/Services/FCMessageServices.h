//
//  HLMessageServices.h
//  HotlineSDK
//
//  Created by user on 03/11/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCChannels.h"


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

@interface FCMessageServices : NSObject

+(void)fetchChannelsAndMessagesWithFetchType:(enum MessageFetchType) priority
                                     source :(enum MessageRequestSource ) requestSource
                                  andHandler:(void (^)(NSError *))handler;

+(NSURLSessionDataTask *)fetchAllChannels:(void (^)(NSArray<FCChannels *> *channels, NSError *error))handler;

+(void)fetchMessagesForSrc:(enum MessageRequestSource) requestSource andCompletion:(void(^)(NSError *error))handler;

+(void)uploadMessage:(FCMessages *)pMessage toConversation:(FCConversations *)conversation onChannel:(FCChannels *)channel;

+(void)uploadNewMessage:(FCMessages *)pMessage toConversation:(FCConversations *)conversation onChannel:(FCChannels *)channel;

+(void)uploadNewMessage:(FCMessages *)pMessage toConversation:(FCConversations *)conversation onChannel:(FCChannels *)channel withCompletion:(void(^)(NSError *error))completion;

+(void)uploadPictureMessage:(FCMessages *)pMessage toConversation:(FCConversations *)conversation withCompletion:(void (^)())completion;
                                                               
+(void)markMarketingMessageAsClicked:(NSNumber *)marketingId;

+(void)uploadAllUnuploadedMessages:(NSArray *)messages index:(NSInteger)currentIndex;

+(void)markMarketingMessageAsRead:(FCMessages *)message context:(NSManagedObjectContext *)context;

+(void)postCSATWithID:(NSManagedObjectID *)csatObjectID completion:(void (^)(NSError *))handler;

+(void)uploadUnuploadedCSAT;

+(void) markUploadFailedAndSaveMessage:(FCMessages *) message inChannel: (FCChannels*) channel;

@end
