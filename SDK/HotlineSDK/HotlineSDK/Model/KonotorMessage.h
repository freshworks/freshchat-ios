//
//  KonotorMessage.h
//  Konotor
//
//  Created by Vignesh G on 15/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "KonotorDataManager.h"
#import "HLChannel.h"
#import "KonotorMessageBinary.h"
#import <ImageIO/ImageIO.h>
#import <UIKit/UIImage.h>
#import "Konotor.h"

@class KonotorConversation;

NS_ASSUME_NONNULL_BEGIN

@interface KonotorMessage : NSManagedObject

@property (nullable, nonatomic, retain) NSNumber *articleID;
@property (nullable, nonatomic, retain) NSString *actionLabel;
@property (nullable, nonatomic, retain) NSString *actionURL;
@property (nullable, nonatomic, retain) NSString *audioURL;
@property (nullable, nonatomic, retain) NSNumber *bytes;
@property (nullable, nonatomic, retain) NSNumber *createdMillis;
@property (nullable, nonatomic, retain) NSNumber *durationInSecs;
@property (nonatomic) BOOL isDownloading;
@property (nonatomic) BOOL isMarkedForUpload;
@property (nullable, nonatomic, retain) NSNumber *marketingId;
@property (nullable, nonatomic, retain) NSString *messageAlias;
@property (nonatomic) BOOL messageRead;

@property (nullable, nonatomic, retain) NSNumber *messageType;
@property (nullable, nonatomic, retain) NSString *messageUserId;
@property (nullable, nonatomic, retain) NSString *picCaption;
@property (nullable, nonatomic, retain) NSNumber *picHeight;
@property (nullable, nonatomic, retain) NSNumber *picThumbHeight;
@property (nullable, nonatomic, retain) NSString *picThumbUrl;
@property (nullable, nonatomic, retain) NSNumber *picThumbWidth;
@property (nullable, nonatomic, retain) NSString *picUrl;
@property (nullable, nonatomic, retain) NSNumber *picWidth;
@property (nullable, nonatomic, retain) NSNumber *read;
@property (nullable, nonatomic, retain) NSString *text;
@property (nullable, nonatomic, retain) NSNumber *uploadStatus;
@property (nullable, nonatomic, retain) HLChannel *belongsToChannel;
@property (nullable, nonatomic, retain) KonotorConversation *belongsToConversation;
@property (nullable, nonatomic, retain) KonotorMessageBinary *hasMessageBinary;

//@property (nonatomic, retain) NSString *marketingId;
+(NSArray *) getAllMessagesForDefaultConversation;
+(NSArray *) getAllMessagesForConversation: (NSString* )conversationID;
+(KonotorMessage *) retriveMessageForMessageId: (NSString *)messageId;
-(NSString *) getJSON;
+(NSString *)generateMessageID;
+(KonotorMessage *)createNewMessage:(NSDictionary *)message;
-(void) associateMessageToConversation: (KonotorConversation *)conversation;
+(KonotorMessage *)saveTextMessageInCoreData:(NSString *)text onConversation:(KonotorConversation *)conversation;
+(KonotorMessage *)savePictureMessageInCoreData:(UIImage *)image withCaption: (NSString *) caption onConversation:(KonotorConversation *)conversation;
+(void)uploadAllUnuploadedMessages;
-(void) markAsReadwithNotif:(BOOL) notif;
-(void) markAsUnread;
+(void)markAllMessagesAsRead;
+(void) markMarketingMessageAsClicked:(NSNumber *) marketingId;
+(BOOL) setBinaryImage:(NSData *)imageData forMessageId:(NSString *)messageId;
+(BOOL) setBinaryImageThumbnail:(NSData *)imageData forMessageId:(NSString *)messageId;
-(BOOL) isMarketingMessage;
+(KonotorMessageData *)getWelcomeMessageForChannel:(HLChannel *)channel;
+(NSArray *)getAllMesssageForChannel:(HLChannel *)channel;

NS_ASSUME_NONNULL_END

@end