//
//  Konotor.h
//  Konotor
//
//  Created by Vignesh G on 04/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIImage.h>

@protocol KonotorDelegate <NSObject>

@optional

-(void) didFinishPlaying:(NSString *)messageID;
-(void) didStartPlaying:(NSString *)messageID;

-(void) didFinishDownloadingMessages;

-(void) didFinishUploading: (NSString *)messageID;
-(void) didEncounterErrorWhileUploading: (NSString *) messageID;
-(void) didEncounterErrorWhileDownloading: (NSString *)messageID;
-(void) didEncounterErrorWhileDownloadingConversations;

-(BOOL) handleRemoteNotification:(NSDictionary*)userInfo;
-(BOOL) handleRemoteNotification:(NSDictionary*)userInfo withShowScreen:(BOOL)showScreen;

@end

enum KonotorMessageType {
    KonotorMessageTypeText = 1,
    KonotorMessageTypeAudio = 2,
    KonotorMessageTypePicture = 3,
    KonotorMessageTypeHTML = 4,
    KonotorMessageTypePictureV2 = 5
    };

enum KonotorMessageUploadStatus
{
 MessageNotUploaded= 0,
 MessageUploading =1,
 MessageUploaded =2
};


@interface Konotor : NSObject

+(void) InitWithAppID: (NSString *) AppID AppKey: (NSString *) AppKey withDelegate:(id) delegate;
+(void) setDelegate:(id) delegate;
+(BOOL) handleRemoteNotification:(NSDictionary*)userInfo;
+(BOOL) handleRemoteNotification:(NSDictionary*)userInfo withShowScreen:(BOOL)showScreen;
+(BOOL) addDeviceToken:(NSData *) deviceToken;
+(void) setUserIdentifier: (NSString *) UserIdentifier;
+(void) setUserName: (NSString *) fullName;
+(void) setUserEmail: (NSString *) email;
+(void) setCustomUserProperty:(NSString *) value forKey: (NSString*) key;
+(void) setWelcomeMessage:(NSString *) text;
+(void) setUnreadWelcomeMessage:(NSString *) text;
+(BOOL) setBinaryImage:(NSData *)imageData forMessageId:(NSString *)messageId;
+(BOOL) setBinaryImageThumbnail:(NSData *)imageData forMessageId:(NSString *)messageId;
+(BOOL) isUserMe:(NSString *) userId;
+(BOOL) startRecording;
+(NSString*) stopRecording;
+ (NSTimeInterval) getTimeElapsedSinceStartOfRecording;
+(BOOL) cancelRecording;

+(BOOL) playMessageWithMessageID:(NSString *) messageID;
+(BOOL) playMessageWithMessageID:(NSString *) messageID atTime:(double) time;
+(BOOL) StopPlayback;
+(float) getDecibelLevel;
+(double) getCurrentPlayingAudioTime;
+(NSString *)getCurrentPlayingMessageID;


+(void) uploadVoiceRecordingWithMessageID: (NSString *)messageID;
+(void) uploadTextFeedback:(NSString *)textFeedback;
+(void) uploadImage:(UIImage *) image;
+(void) uploadImage:(UIImage *) image withCaption:(NSString*) caption;

+(void) DownloadAllMessages;
+(void) sendAllUnsentMessages;

+(void)MarkMessageAsRead:(NSString *) messageID;

+(void)markAllMessagesAsRead;

+(void) MarkMarketingMessageAsClicked:(NSNumber *) marketingId;

+(void) shareEventWithMessageID: (NSString *)messageID shareType:(NSString*)shareType;
+(NSArray *) getAllMessagesForConversation:(NSString *)conversationID;
+(NSArray *) getAllMessagesForDefaultConversation;
+(NSArray *) getAllConversations;
+(BOOL) areConversationsDownloading;
+(int) getUnreadMessagesCount;

+(void) newSession;
+(BOOL) isPushEnabled;
+(BOOL) isPoweredByHidden;
+(void) setSecretKey:(NSString*)key;

@end

@interface KonotorConversationData : NSObject

@property (strong, nonatomic) NSString *conversationAlias;
@property (strong, nonatomic) NSNumber *lastUpdated;
@property (strong, nonatomic) NSNumber *unreadMessagesCount;

@end

@interface KonotorMessageData : NSObject

@property (nonatomic, retain) NSNumber * createdMillis;
@property (nonatomic, retain) NSNumber * messageType;
@property (nonatomic, retain) NSString * messageUserId;
@property (nonatomic, retain) NSString * messageId;
@property (nonatomic, retain) NSNumber * bytes;
@property (nonatomic, retain) NSNumber * durationInSecs;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSNumber * uploadStatus;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSNumber * picHeight,*picWidth, *picThumbHeight, *picThumbWidth;
@property (nonatomic, retain) NSData *picData, *picThumbData;
@property (nonatomic, retain) NSString * picUrl, *picThumbUrl;
@property (nonatomic, retain) NSString *picCaption;
@property (nonatomic, retain) NSString *actionLabel, *actionURL;
@property (nonatomic, retain) NSData *audioData;
@property (nonatomic) BOOL  messageRead;
@property (nonatomic) BOOL isMarketingMessage;

@end