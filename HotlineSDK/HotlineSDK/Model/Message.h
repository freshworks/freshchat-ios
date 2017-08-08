//
//  Message.h
//  HotlineSDK
//
//  Created by user on 01/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "Hotline.h"
#import "HLChannel.h"
#import "HLMacros.h"
#import "FDUtilities.h"
#import "KonotorConversation.h"
#import "HLMessageServices.h"
#import <UIKit/UIImage.h>
#import "HLCoreServices.h"
#import "MessageData.h"
#import "Fragment.h"
#import "Konotor.h"

#define MESSAGE_NOT_UPLOADED 0
#define MESSAGE_UPLOADING 1
#define MESSAGE_UPLOADED 2

#define USER_TYPE_MOBILE @0
#define USER_TYPE_OWNER @1
#define USER_TYPE_AGENT @2

NS_ASSUME_NONNULL_BEGIN

@interface Message : NSManagedObject

    @property (nullable, nonatomic, retain) NSNumber *channelId;
    @property (nullable, nonatomic, retain) NSString *conversationId;
    @property (nullable, nonatomic, retain) NSString *createdMillis;
    @property (nullable, nonatomic, retain) NSNumber *marketingId;
    @property (nullable, nonatomic, retain) NSString *messageAlias;
    @property (nullable, nonatomic, retain) NSString *messageUserAlias;
    @property (nullable, nonatomic, retain) NSNumber *messageUserType;
    @property (nullable, nonatomic, retain) NSNumber *uploadStatus;
    @property (nonatomic) BOOL isMarkedForUpload;
    @property (nonatomic) BOOL isWelcomeMessage;
    @property (nonatomic) BOOL isRead;
    @property (nonatomic) BOOL isDownloading;
    @property (nullable, nonatomic, retain) HLChannel *belongsToChannel;
    @property (nullable, nonatomic, retain) KonotorConversation *belongsToConversation;

    +(Message *)getWelcomeMessageForChannel:(HLChannel *)channel;
    +(Message *) retriveMessageForMessageId: (NSString *)messageId;
    -(NSString *) getJSON;
    +(NSString *)generateMessageID;
    +(Message *)createNewMessage:(NSDictionary *)message toChannelID:(NSNumber *)channelId;
    -(void) associateMessageToConversation: (KonotorConversation *)conversation;
    +(Message *)saveMessageInCoreData:(NSArray *)fragmentsInfo onConversation:(KonotorConversation *)conversation;
    +(void)uploadAllUnuploadedMessages;
    -(void) markAsRead;
    -(void) markAsUnread;
    +(NSInteger)getUnreadMessagesCountForChannel:(NSNumber *)channel;
    +(void) markAllMessagesAsReadForChannel:(HLChannel *)channel;
    -(BOOL) isMarketingMessage;
    +(NSArray *) getAllMesssageForChannel:(HLChannel *)channel;
    +(bool) hasUserMessageInContext:(NSManagedObjectContext *)context;
    +(long long) lastMessageTimeInContext:(NSManagedObjectContext *)context;
    +(long) daysSinceLastMessageInContext:(NSManagedObjectContext *)context;
    -(NSMutableDictionary *) convertMessageToDictionary;
    -(NSString *)getDetailDescriptionForMessage;



@end

NS_ASSUME_NONNULL_END
