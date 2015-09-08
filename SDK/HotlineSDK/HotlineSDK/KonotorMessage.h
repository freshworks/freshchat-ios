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
#import <ImageIO/ImageIO.h>
#import <UIKit/UIImage.h>

@class KonotorConversation;

@interface KonotorMessage : NSManagedObject

@property (nonatomic, retain) NSNumber * messageType;
@property (nonatomic, retain) NSString * messageUserId;
@property (nonatomic, retain) NSString * messageAlias;
@property (nonatomic, retain) NSNumber * bytes;
@property (nonatomic, retain) NSNumber * durationInSecs;
@property (nonatomic, retain) NSNumber * picHeight,*picThumbHeight;
@property (nonatomic, retain) NSNumber * picWidth, *picThumbWidth;
@property (nonatomic, retain) NSString * picCaption;

@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSNumber * createdMillis;
@property (nonatomic) BOOL isMarkedForUpload;
@property (nonatomic, retain) NSNumber * uploadStatus;
@property (nonatomic, retain) NSManagedObject *hasMessageBinary;
@property (nonatomic, retain) KonotorConversation *belongsToConversation;
@property (nonatomic) BOOL isDownloading;
@property (nonatomic) BOOL messageRead;
@property (nonatomic, retain) NSString *audioURL;
//@property (nonatomic, retain) NSString *marketingId;
@property (nonatomic, retain) NSNumber *marketingId;
@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) NSString *picUrl;
@property (nonatomic, retain) NSString *picThumbUrl;
@property (nonatomic, retain) NSString *actionLabel, *actionURL;



+(NSArray *) GetAllMessagesForDefaultConversation;
+(NSArray *) GetAllMessagesForConversation: (NSString* )conversationID;
+(KonotorMessage *) RetriveMessageForMessageId: (NSString *)messageId;
+(KonotorMessage *) CreateNewMessage: (KonotorMessage *)message;
-(NSString *) GetJSON;
+(NSString *) GenerateMessageID;
-(void) AssociateMessageToConversation: (KonotorConversation *)conversation;
+(NSString *) SaveTextMessageInCoreData : (NSString *)text;
+(NSString *) SavePictureMessageInCoreData:(UIImage *)image withCaption: (NSString *)caption;
+(void) InsertLocalTextMessage : (NSString *) text Read:(BOOL) read IsWelcomeMessage:(BOOL) isWelcomeMessage;
+ (void) updateWelcomeMessageText:(NSString*)text;
+(void) UploadAllUnuploadedMessages;
-(void) MarkAsReadwithNotif:(BOOL) notif;
-(void) MarkAsUnread;
+(void) MarkAllMessagesAsRead;
+(void) MarkMarketingMessageAsClicked:(NSNumber *) marketingId;
+(BOOL) setBinaryImage:(NSData *)imageData forMessageId:(NSString *)messageId;
+(BOOL) setBinaryImageThumbnail:(NSData *)imageData forMessageId:(NSString *)messageId;
-(BOOL) isMarketingMessage;

@end
