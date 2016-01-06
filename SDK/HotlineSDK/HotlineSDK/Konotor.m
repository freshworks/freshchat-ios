//
//  Konotor.m
//  Konotor
//
//  Created by Vignesh G on 04/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import "Konotor.h"
#import "KonotorDataManager.h"
#import "KonotorAudioRecorder.h"
#import "KonotorAudioPlayer.h"
#import "WebServices.h"
#import "HLMacros.h"
#import "HLMessageServices.h"
#import "FDChannelUpdater.h"
#import "FDSolutionUpdater.h"
#import "FDUtilities.h"

static NSString *kon_unlock_key = nil;

@implementation Konotor

static id <KonotorDelegate> _delegate;

+(id) delegate{
    return _delegate;
}

+(void) setDelegate:(id)delegate{
    _delegate = delegate;
}

+(void) sendAllUnsentMessages{
    //Check if app init is required before this call
    [KonotorMessage uploadAllUnuploadedMessages];
}

+(void) DownloadAllMessages
{
    [KonotorConversation DownloadAllMessages];
}

+(double) getCurrentPlayingAudioTime
{
    return [KonotorAudioPlayer audioPlayerGetCurrentTime];
}

+(BOOL) startRecording
{
    return [KonotorAudioRecorder startRecording];
}
+(NSString *) stopRecording
{
    return[KonotorAudioRecorder stopRecording];
}

+(NSString *) stopRecordingOnConversation:(KonotorConversation*)conversation
{
    return [KonotorAudioRecorder stopRecordingOnConversation:conversation];
}

+ (NSTimeInterval) getTimeElapsedSinceStartOfRecording
{
    return[KonotorAudioRecorder getTimeElapsedSinceStartOfRecording];

}

+(BOOL) cancelRecording
{
    return[KonotorAudioRecorder cancelRecording];

}

+(float) getDecibelLevel
{
  return [KonotorAudioRecorder getDecibelLevel];
}
+(void) uploadVoiceRecordingWithMessageID: (NSString *)MessageID
{
    [KonotorAudioRecorder SendRecordingWithMessageID:MessageID];
    [[Konotor delegate] didStartUploadingNewMessage];
}

+(void) uploadVoiceRecordingWithMessageID: (NSString *)MessageID toConversationID: (NSString *)ConversationID onChannel:(HLChannel*)channel{
    [KonotorAudioRecorder SendRecordingWithMessageID:MessageID toConversationID:ConversationID onChannel:channel];
    [[Konotor delegate] didStartUploadingNewMessage];
}

+(BOOL) StopPlayback{
    return [KonotorAudioPlayer StopMessage];
}

+(NSString *)getCurrentPlayingMessageID{
    return [KonotorAudioPlayer currentPlaying:nil set:NO ];
}

+(void)uploadTextFeedback:(NSString *)textFeedback onConversation:(KonotorConversation *)conversation onChannel:(HLChannel *)channel{
    KonotorMessage *message = [KonotorMessage saveTextMessageInCoreData:textFeedback onConversation:conversation];
    [channel addMessagesObject:message];
    [[KonotorDataManager sharedInstance]save];
    [KonotorWebServices uploadMessage:message toConversation:conversation onChannel:channel];
    [[Konotor delegate] didStartUploadingNewMessage];
}

+(void)uploadImage:(UIImage *)image onConversation:(KonotorConversation *)conversation onChannel:(HLChannel *)channel{
    [self uploadImage:image withCaption:nil onConversation:conversation onChannel:channel];
}

+(void) uploadImage:(UIImage *)image withCaption:(NSString *)caption onConversation:(KonotorConversation *)conversation onChannel:(HLChannel *)channel{
    KonotorMessage *message = [KonotorMessage savePictureMessageInCoreData:image withCaption:caption onConversation:conversation];
    [channel addMessagesObject:message];
    [KonotorWebServices uploadMessage:message toConversation:conversation onChannel:channel];
    [[Konotor delegate] didStartUploadingNewMessage];
}


+(void)MarkMessageAsRead:(NSString *) messageID
{
    KonotorMessage *message = [KonotorMessage retriveMessageForMessageId:messageID];
    if(message)
    {
        [message markAsReadwithNotif:YES];
    }
}

+(void) MarkMarketingMessageAsClicked:(NSNumber *) marketingId;
{
    if(marketingId)
    {
        [KonotorMessage markMarketingMessageAsClicked:marketingId ];
    }
}
+(void)markAllMessagesAsRead
{
    [KonotorMessage markAllMessagesAsRead];

}
+(BOOL) playMessageWithMessageID:(NSString *) messageID
{
    return [KonotorAudioPlayer playMessageWithMessageID:messageID];
    
}

+(BOOL) playMessageWithMessageID:(NSString *) messageID atTime:(double)time
{
    return [KonotorAudioPlayer PlayMessage:messageID atTime:time];
    
}

+(BOOL) setBinaryImage:(NSData *)imageData forMessageId:(NSString *)messageId
{
    return [KonotorMessage setBinaryImage:imageData forMessageId:messageId];
}
+(BOOL) setBinaryImageThumbnail:(NSData *)imageData forMessageId:(NSString *)messageId
{
    return [KonotorMessage setBinaryImageThumbnail:imageData forMessageId:messageId];
}

+(NSArray *) getAllMessagesForConversation:(NSString *) conversationID
{
    return [KonotorMessage getAllMessagesForConversation:conversationID];
}

+(BOOL)isUserMe:(NSString *)userId{
    //TODO: This will break migration from existing konotor SDK - Rex
    // Migration needs to convert existing userIds or dont use a hardcoded userId.
    NSString *currentUserID = @"Sender-User";
    if(currentUserID){
        if([currentUserID isEqualToString:userId]){
            return YES;
        }
    }
    return NO;
}

//////Start of undocumented functions/////

+(void) conversationsDownloaded
{
    if([Konotor delegate])
    {
        if([[Konotor delegate] respondsToSelector:@selector(didFinishDownloadingMessages) ])
        {
    
            [[Konotor delegate] didFinishDownloadingMessages];
        }
    }
}

+(void)UploadFinishedNotifcation: (NSString *) messageID{
    if([Konotor delegate]){
        if([[Konotor delegate] respondsToSelector:@selector(didFinishUploading:) ]){
            [[Konotor delegate] didFinishUploading:messageID];
        }
    }
}

+(void)UploadFailedNotifcation: (NSString *) messageID
{
    if([Konotor delegate])
    {
        if([[Konotor delegate] respondsToSelector:@selector(didEncounterErrorWhileUploading:) ])
        {
            
            [[Konotor delegate] didEncounterErrorWhileUploading:messageID];
        }
    }
    
}

+(void) messageFinishedPlayingNotification:(NSString *) messageID
{
    if([Konotor delegate])
    {
        if([[Konotor delegate] respondsToSelector:@selector(didFinishPlaying:) ])
        {
            
            [[Konotor delegate] didFinishPlaying:messageID];
        }
    }
}

+(void) MediaStartedNotification:(NSString *) messageID
{
    if([Konotor delegate])
    {
        if([[Konotor delegate] respondsToSelector:@selector(didStartPlaying:) ])
        {
            
            [[Konotor delegate] didStartPlaying:messageID];
        }
    }
}

+(void) MediaDownloadFailedNotification:(NSString *) messageID
{
    if([Konotor delegate])
    {
        if([[Konotor delegate] respondsToSelector:@selector(didEncounterErrorWhileDownloading:) ])
        {
            
            [[Konotor delegate] didEncounterErrorWhileDownloading:messageID];
        }
    }
}

+(void) conversationsDownloadFailed
{
    if([Konotor delegate])
    {
        if([[Konotor delegate] respondsToSelector:@selector(didEncounterErrorWhileDownloadingConversations) ])
        {
            
            [[Konotor delegate] didEncounterErrorWhileDownloadingConversations];
        }
    }
}

@end

@implementation KonotorConversationData

@end

@implementation KonotorMessageData

@end