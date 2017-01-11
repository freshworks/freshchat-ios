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

#define MESSAGE_NOT_UPLOADED 0
#define MESSAGE_UPLOADING 1
#define MESSAGE_UPLOADED 2

#define USER_TYPE_MOBILE @"0"
#define USER_TYPE_OWNER @"1"
#define USER_TYPE_AGENT @"2"

enum KonotorMessageType {
    KonotorMessageTypeText       = 1,
    KonotorMessageTypeAudio      = 2,
    KonotorMessageTypePicture    = 3,
    KonotorMessageTypeHTML       = 4,
    KonotorMessageTypePictureV2  = 5
};

enum KonotorMessageUploadStatus{
    MessageNotUploaded = 0,
    MessageUploading   = 1,
    MessageUploaded    = 2
};

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
@property (nonatomic) BOOL isWelcomeMessage;
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

+(KonotorMessage *)getWelcomeMessageForChannel:(HLChannel *)channel;
+(KonotorMessage *) retriveMessageForMessageId: (NSString *)messageId;
-(NSString *) getJSON;
+(NSString *)generateMessageID;
+(KonotorMessage *)createNewMessage:(NSDictionary *)message;
-(void) associateMessageToConversation: (KonotorConversation *)conversation;
+(KonotorMessage *)saveTextMessageInCoreData:(NSString *)text onConversation:(KonotorConversation *)conversation;
+(KonotorMessage *)savePictureMessageInCoreData:(UIImage *)image withCaption: (NSString *) caption onConversation:(KonotorConversation *)conversation;
+(void)uploadAllUnuploadedMessages;
-(void) markAsRead;
-(void) markAsUnread;
+(NSInteger)getUnreadMessagesCountForChannel:(NSNumber *)channel;
+(void) markAllMessagesAsReadForChannel:(HLChannel *)channel;
+(BOOL) setBinaryImage:(NSData *)imageData forMessageId:(NSString *)messageId;
+(BOOL) setBinaryImageThumbnail:(NSData *)imageData forMessageId:(NSString *)messageId;
-(BOOL) isMarketingMessage;
+(NSArray *)getAllMesssageForChannel:(HLChannel *)channel;
+(bool) hasUserMessageInContext:(NSManagedObjectContext *)context;

@end

@interface KonotorMessageData : NSObject

@property (nullable, nonatomic, retain) NSNumber * articleID;
@property (nullable, nonatomic, retain) NSNumber * createdMillis;
@property (nullable, nonatomic, retain) NSNumber * messageType;
@property (nullable, nonatomic, retain) NSString * messageUserId;
@property (nullable, nonatomic, retain) NSString * messageId;
@property (nullable, nonatomic, retain) NSNumber * bytes;
@property (nullable, nonatomic, retain) NSNumber * durationInSecs;
@property (nullable, nonatomic, retain) NSNumber * read;
@property (nullable, nonatomic, retain) NSNumber * uploadStatus;
@property (nullable, nonatomic, retain) NSString * text;
@property (nullable, nonatomic, retain) NSNumber * picHeight,*picWidth, *picThumbHeight, *picThumbWidth;
@property (nullable, nonatomic, retain) NSData *picData, *picThumbData;
@property (nullable, nonatomic, retain) NSString * picUrl, *picThumbUrl;
@property (nullable, nonatomic, retain) NSString *picCaption;
@property (nullable, nonatomic, retain) NSString *actionLabel, *actionURL;
@property (nullable, nonatomic, retain) NSData *audioData;
@property (nonatomic) BOOL isWelcomeMessage;
@property (nonatomic) BOOL  messageRead;
@property (nonatomic) BOOL isMarketingMessage;
@property (nullable, nonatomic, retain) NSNumber *marketingId;

@end

NS_ASSUME_NONNULL_END
