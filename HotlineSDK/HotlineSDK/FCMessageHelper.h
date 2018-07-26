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
#import "FCConversations.h"
#import "FreshchatSDK.h"

//TODO: Remove this class

@protocol KonotorDelegate <NSObject>

@optional

-(void) didFinishDownloadingMessages;

-(void) didFinishUploading: (NSString *)messageID;
-(void) didEncounterErrorWhileUploading: (NSString *) messageID;
-(void) didEncounterErrorWhileDownloading: (NSString *)messageID;
-(void) didNotifyServerError;
-(void) didEncounterErrorWhileDownloadingConversations;

-(void) didStartUploadingNewMessage;

@end

@interface FCMessageHelper : NSObject

+(void) setDelegate:(id) delegate;
+(BOOL) setBinaryImage:(NSData *)imageData forMessageId:(NSString *)messageId;
+(BOOL) setBinaryImageThumbnail:(NSData *)imageData forMessageId:(NSString *)messageId;
+(BOOL) isUserMe:(NSString *) userId;
+(BOOL) isCurrentUser:(NSNumber *) userId;
+(NSString*) stopRecording;
+(NSString *) stopRecordingOnConversation:(FCConversations*)conversation;
+ (NSTimeInterval) getTimeElapsedSinceStartOfRecording;
+(BOOL) cancelRecording;

+(BOOL) playMessageWithMessageID:(NSString *) messageID;
+(BOOL) playMessageWithMessageID:(NSString *) messageID atTime:(double) time;
+(BOOL) StopPlayback;
+(double) getCurrentPlayingAudioTime;
+(NSString *)getCurrentPlayingMessageID;

+(void) uploadMessageWithImage:(UIImage *)image textFeed:(NSString *)textFeedback onConversation:(FCConversations *)conversation andChannel:(FCChannels *)channel;
+(void)uploadImage:(UIImage *)image onConversation:(FCConversations *)conversation onChannel:(FCChannels *)channel;
+(void)uploadImage:(UIImage *)image withCaption:(NSString *)caption onConversation:(FCConversations *)conversation onChannel:(FCChannels *)channel;

+(void)uploadNewMessage:(NSArray *)fragmentsInfo onConversation:(FCConversations *)conversation onChannel:(FCChannels *)channel;
+(void)uploadNewMsgWithImage:(UIImage *)image textFeed:(NSString *)caption onConversation:(FCConversations *)conversation andChannel:(FCChannels *)channel;
+(void) uploadVoiceRecordingWithMessageID: (NSString *)MessageID toConversationID: (NSString *)ConversationID onChannel:(FCChannels*)channel;

//TODO: The following are indirectly called by KonotorDelegate and need to be removed.
+(void) MediaDownloadFailedNotification:(NSString *) messageID;
+(void) conversationsDownloadFailed;
+(void) conversationsDownloaded;
+(void) UploadFinishedNotification: (NSString *) messageID;
+(void) UploadFailedNotification: (NSString *) messageID;
+(void) NotifyServerError;
+(BOOL) isRecording;




@end
