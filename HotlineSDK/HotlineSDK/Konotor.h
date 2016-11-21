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
#import "KonotorConversation.h"
#import "Hotline.h"

//TODO: Remove this class

@protocol KonotorDelegate <NSObject>

@optional

-(void) didFinishDownloadingMessages;

-(void) didFinishUploading: (NSString *)messageID;
-(void) didEncounterErrorWhileUploading: (NSString *) messageID;
-(void) didEncounterErrorWhileDownloading: (NSString *)messageID;
-(void) didEncounterErrorFromServer;
-(void) didEncounterErrorWhileDownloadingConversations;

-(void) didStartUploadingNewMessage;

@end

@interface Konotor : NSObject

+(void) setDelegate:(id) delegate;
+(BOOL) setBinaryImage:(NSData *)imageData forMessageId:(NSString *)messageId;
+(BOOL) setBinaryImageThumbnail:(NSData *)imageData forMessageId:(NSString *)messageId;
+(BOOL) isUserMe:(NSString *) userId;
+(NSString*) stopRecording;
+(NSString *) stopRecordingOnConversation:(KonotorConversation*)conversation;
+ (NSTimeInterval) getTimeElapsedSinceStartOfRecording;
+(BOOL) cancelRecording;

+(BOOL) playMessageWithMessageID:(NSString *) messageID;
+(BOOL) playMessageWithMessageID:(NSString *) messageID atTime:(double) time;
+(BOOL) StopPlayback;
+(double) getCurrentPlayingAudioTime;
+(NSString *)getCurrentPlayingMessageID;

+(void)uploadTextFeedback:(NSString *)textFeedback onConversation:(KonotorConversation *)conversation onChannel:(HLChannel *)channel;
+(void)uploadImage:(UIImage *)image onConversation:(KonotorConversation *)conversation onChannel:(HLChannel *)channel;
+(void)uploadImage:(UIImage *)image withCaption:(NSString *)caption onConversation:(KonotorConversation *)conversation onChannel:(HLChannel *)channel;
+(void) uploadVoiceRecordingWithMessageID: (NSString *)MessageID toConversationID: (NSString *)ConversationID onChannel:(HLChannel*)channel;
+ (BOOL) showNotificationDisabledAlert;
+ (void) setDisabledNotificationAlertShown:(BOOL) shown;

//TODO: The following are indirectly called by KonotorDelegate and need to be removed.
+(void) MediaDownloadFailedNotification:(NSString *) messageID;
+(void) conversationsDownloadFailed;
+(void) conversationsDownloaded;
+(void) UploadFinishedNotification: (NSString *) messageID;
+(void) UploadFailedNotification: (NSString *) messageID;
+(void) ServerProblemNotification;




@end
