//
//  Konotor.m
//  Konotor
//
//  Created by Vignesh G on 04/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import "Konotor.h"
#import "KonotorUser.h"
#import "KonotorDataManager.h"
#import "KonotorAudioRecorder.h"
#import "KonotorApp.h"
#import "KonotorAudioPlayer.h"
#import "WebServices.h"
#import "KonotorShareMessageEvent.h"
#import "HLMacros.h"
#import "HLMessageServices.h"
#import "FDChannelUpdater.h"
#import "FDSolutionUpdater.h"

extern  bool KONOTOR_APP_INIT_DONE;
static NSString *kon_unlock_key = nil;

@implementation Konotor

static id <KonotorDelegate> _delegate;

+(id) delegate{
    return _delegate;
}

+(void) setDelegate:(id)delegate{
    _delegate = delegate;
}

+(void) setSecretKey:(NSString*)key{
    kon_unlock_key=key;
}

+(void) initWithAppID:(NSString *)AppID AppKey:(NSString *)AppKey withDelegate:(id)delegate{
    if(KONOTOR_APP_INIT_DONE){
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(),^{
        _delegate = delegate;
        [KonotorApp initWithAppID:AppID WithAppKey:AppKey];
        [KonotorUser InitUser];
        [KonotorApp UpdateAppAndSDKVersions];
    });
}

+(void) sendAllUnsentMessages{
    if(KONOTOR_APP_INIT_DONE){
        [KonotorMessage uploadAllUnuploadedMessages];
    }
}

+(void) PerformAllPendingTasks{
    FDLog(@"Performing pending tasks");
    dispatch_async(dispatch_get_main_queue(),^{
        if(KONOTOR_APP_INIT_DONE){
            [[[FDChannelUpdater alloc]init] fetch];
            [[[FDSolutionUpdater alloc]init] fetch];
            [KonotorShareMessageEvent UploadAllUnuploadedEvents];
            [KonotorCustomProperty UploadAllUnuploadedProperties];
            [KonotorMessage uploadAllUnuploadedMessages];
            [KonotorConversation DownloadAllMessages];
            [KonotorApp SendCachedTokenIfNotUpdated];
            [KonotorApp UpdateAppAndSDKVersions];
        }
    });
}

+(void) DownloadAllMessages
{
    [KonotorConversation DownloadAllMessages];
}

+(BOOL) handleRemoteNotification:(NSDictionary*)userInfo
{
    return [_delegate handleRemoteNotification:userInfo];
}

+(BOOL) handleRemoteNotification:(NSDictionary*)userInfo withShowScreen:(BOOL)showScreen
{
    return [_delegate handleRemoteNotification:userInfo withShowScreen:showScreen];
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
    [KonotorWebServices uploadMessage:message toConversation:conversation onChannel:channel];
    [[Konotor delegate] didStartUploadingNewMessage];
}

+(void)uploadImage:(UIImage *)image onConversation:(KonotorConversation *)conversation onChannel:(HLChannel *)channel{
    [self uploadImage:image withCaption:nil onConversation:conversation onChannel:channel];
}

+(void) uploadImage:(UIImage *)image withCaption:(NSString *)caption onConversation:(KonotorConversation *)conversation onChannel:(HLChannel *)channel{
    KonotorMessage *message = [KonotorMessage savePictureMessageInCoreData:image withCaption:caption onConversation:conversation];
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

+(NSArray *) getAllMessagesForDefaultConversation
{
    return [KonotorMessage getAllMessagesForDefaultConversation];
}

+(NSArray*) getAllConversations
{
    return [KonotorConversation ReturnAllConversations];
}


+(NSArray *) getAllMessagesForConversation:(NSString *) conversationID
{
    return [KonotorMessage getAllMessagesForConversation:conversationID];
}

+(void) setWelcomeMessage:(NSString *) text
{
    if(![KonotorApp hasWelcomeMessageDisplayed])
    {
        [KonotorMessage insertLocalTextMessage:text Read:YES IsWelcomeMessage:YES];
        [KonotorApp setWelcomeMessageStatus:YES];
    }
    else{
        [KonotorMessage updateWelcomeMessageText:text];
    }
}

+(void) setUnreadWelcomeMessage:(NSString *) text
{
    if(![KonotorApp hasWelcomeMessageDisplayed])
    {
        [KonotorMessage insertLocalTextMessage:text Read:NO IsWelcomeMessage:YES];
        [KonotorApp setWelcomeMessageStatus:YES];
    }
    else{
        [KonotorMessage updateWelcomeMessageText:text];
    }
}

+(int) getUnreadMessagesCount
{
    NSArray* allConvs=[Konotor getAllConversations];
    if((allConvs!=nil)&&([allConvs count]>0))
        return [[(KonotorConversationData*)[allConvs objectAtIndex:0] unreadMessagesCount] intValue];
    else
        return 0;
}

+(BOOL) isUserMe:(NSString *) userId
{
    NSString *currentUserID = [KonotorUser GetUserAlias];
    if(currentUserID)
    {
        if([currentUserID isEqualToString:userId])
            return TRUE;
    }
    
    return FALSE;
}

+(BOOL) addDeviceToken:(NSData *) deviceToken
{
    NSString *tokenStr = [deviceToken description];
    NSString *strDeviceToken = [[[tokenStr stringByReplacingOccurrencesOfString:@"<"withString:@""] stringByReplacingOccurrencesOfString:@">"withString:@""] stringByReplacingOccurrencesOfString:@" "withString:@""] ;
    [KonotorApp addDeviceToken:strDeviceToken];
    return YES;
    
}

+(void) setUserIdentifier: (NSString *) UserIdentifier
{
    [KonotorUser setUserIdentifier:UserIdentifier];
}

+(void) setUserName: (NSString *) fullName
{
    [KonotorUser setUserName:fullName];
}

+(void) setUserEmail: (NSString *) email
{
    [KonotorUser setUserEmail:email];
}

+(void) setCustomUserProperty:(NSString *) value forKey: (NSString*) key
{
    [KonotorUser setCustomUserProperty:value forKey:key];
}

+(void) shareEventWithMessageID: (NSString *)messageID shareType:(NSString*)shareType
{
    KonotorShareMessageEvent* event = [KonotorShareMessageEvent sharedMessageWithID:messageID withShareType:shareType];
    [KonotorWebServices sendShareMessageEvent:event];
    return;
    
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

+(void) newSession{
    dispatch_async(dispatch_get_main_queue(),^{
        [KonotorUser InitUser];
        [Konotor PerformAllPendingTasks];
        [KonotorWebServices DAUCall];
    });
}

+(BOOL) isPushEnabled
{
    if([KonotorApp GetCachedDeviceToken])
        return YES;
    else
        return NO;
}

@end

@implementation KonotorConversationData



@end

@implementation KonotorMessageData



@end
