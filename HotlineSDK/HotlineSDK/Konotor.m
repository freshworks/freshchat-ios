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
#import "HLMacros.h"
#import "HLMessageServices.h"
#import "FDChannelUpdater.h"
#import "FDSolutionUpdater.h"
#import "FDUtilities.h"
#import "HLEventManager.h"
#import "HLEvent.h"

@implementation Konotor

__weak static id <KonotorDelegate> _delegate;

+(id) delegate{
    return _delegate;
}

+(void) setDelegate:(id)delegate{
    _delegate = delegate;
}

+(double) getCurrentPlayingAudioTime
{
    return [KonotorAudioPlayer audioPlayerGetCurrentTime];
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

+(void) uploadVoiceRecordingWithMessageID: (NSString *)MessageID toConversationID: (NSString *)ConversationID onChannel:(HLChannel*)channel{
    
    NSDictionary *properties = @{HLEVENT_PARAM_CHANNEL_ID : channel.channelID,
                                 HLEVENT_PARAM_CHANNEL_NAME : channel.name,
                                 HLEVENT_PARAM_MESSAGE_ID : MessageID,
                                 HLEVENT_PARAM_MESSAGE_TYPE : HLEVENT_MESSAGE_TYPE_AUDIO};
    HLEvent *event = [[HLEvent alloc] initWithEventName:HLEVENT_SENT_MESSAGE andProperty:properties];
    [event saveEvent];
    
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
    
    NSDictionary *properties = @{HLEVENT_PARAM_CHANNEL_ID : channel.channelID,
                                 HLEVENT_PARAM_CHANNEL_NAME : channel.name,
                                 HLEVENT_PARAM_MESSAGE_ID : conversation.conversationAlias,
                                 HLEVENT_PARAM_MESSAGE_TYPE : HLEVENT_MESSAGE_TYPE_TEXT};
    HLEvent *event = [[HLEvent alloc] initWithEventName:HLEVENT_SENT_MESSAGE andProperty:properties];
    [event saveEvent];
    
    KonotorMessage *message = [KonotorMessage saveTextMessageInCoreData:textFeedback onConversation:conversation];
    [channel addMessagesObject:message];
    [[KonotorDataManager sharedInstance]save];
    [HLMessageServices uploadMessage:message toConversation:conversation onChannel:channel];
    [[Konotor delegate] didStartUploadingNewMessage];
}

+(void)uploadImage:(UIImage *)image onConversation:(KonotorConversation *)conversation onChannel:(HLChannel *)channel{
    [self uploadImage:image withCaption:nil onConversation:conversation onChannel:channel];
}

+(void) uploadImage:(UIImage *)image withCaption:(NSString *)caption onConversation:(KonotorConversation *)conversation onChannel:(HLChannel *)channel{
    
    NSDictionary *properties = @{HLEVENT_PARAM_CHANNEL_ID : channel.channelID,
                                 HLEVENT_PARAM_CHANNEL_NAME : channel.name,
                                 HLEVENT_PARAM_MESSAGE_ID : conversation.conversationAlias,
                                 HLEVENT_PARAM_MESSAGE_TYPE : HLEVENT_MESSAGE_TYPE_IMAGE};
    HLEvent *event = [[HLEvent alloc] initWithEventName:HLEVENT_SENT_MESSAGE andProperty:properties];
    [event saveEvent];
    
    KonotorMessage *message = [KonotorMessage savePictureMessageInCoreData:image withCaption:caption onConversation:conversation];
    [channel addMessagesObject:message];
    [HLMessageServices uploadMessage:message toConversation:conversation onChannel:channel];
    [[Konotor delegate] didStartUploadingNewMessage];
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

+(BOOL)isUserMe:(NSString *)userId{
    NSString *currentUserID = USER_TYPE_MOBILE;
    if(currentUserID){
        if([userId isEqualToString:currentUserID]){
            return YES;
        }
    }
    return NO;
}

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

+(void)UploadFinishedNotification: (NSString *) messageID{
    if([Konotor delegate]){
        if([[Konotor delegate] respondsToSelector:@selector(didFinishUploading:) ]){
            [[Konotor delegate] didFinishUploading:messageID];
        }
    }
}

+(void)UploadFailedNotification: (NSString *) messageID
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

+ (BOOL) showNotificationDisabledAlert {
    return ![[FDSecureStore sharedInstance] boolValueForKey:HOTLINE_DEFAULTS_NOTIFICATION_DISABLED_ALERT_SHOWN];
}

+ (void) setDisabledNotificationAlertShown:(BOOL) shown{
    [[FDSecureStore sharedInstance] setBoolValue:shown forKey:HOTLINE_DEFAULTS_NOTIFICATION_DISABLED_ALERT_SHOWN];
}

@end