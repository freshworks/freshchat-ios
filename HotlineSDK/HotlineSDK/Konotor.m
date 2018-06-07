
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
#import "FDUtilities.h"
#import "FDSecureStore.h"
#import <ImageIO/ImageIO.h>
#import "HLUser.h"

#import "Message.h"

#define KONOTOR_IMG_COMPRESSION YES

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

+(BOOL) isRecording{
    return [KonotorAudioRecorder isRecording];
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
    [KonotorAudioRecorder SendRecordingWithMessageID:MessageID toConversationID:ConversationID onChannel:channel];
    [[Konotor delegate] didStartUploadingNewMessage];
}

+(BOOL) StopPlayback{
    return [KonotorAudioPlayer StopMessage];
}

+(NSString *)getCurrentPlayingMessageID{
    return [KonotorAudioPlayer currentPlaying:nil set:NO ];
}

+(void)uploadNewMessage:(NSArray *)fragmentsInfo onConversation:(KonotorConversation *)conversation onChannel:(HLChannel *)channel{
    Message *message = [Message saveMessageInCoreData:fragmentsInfo onConversation:conversation];
    [channel addMessagesObject:message];
    [[KonotorDataManager sharedInstance]save];
    [HLMessageServices uploadNewMessage:message toConversation:conversation onChannel:channel];    
    [[Konotor delegate] didStartUploadingNewMessage];
    
}

+(void)uploadNewMsgWithImage:(UIImage *)image textFeed:(NSString *)caption onConversation:(KonotorConversation *)conversation andChannel:(HLChannel *)channel{
    //Upload the image with caption first then upload the message
    NSMutableArray *fragmentsInfo = [[NSMutableArray alloc] init];
    if(image){
        NSData *imageData, *thumbnailData;
        float imageWidth,imageHeight,imageThumbHeight,imageThumbWidth;
        
        imageData = UIImageJPEGRepresentation(image, 0.5);
        CGImageSourceRef src = CGImageSourceCreateWithData( (__bridge CFDataRef)(imageData), NULL);
        NSDictionary *osptions = [[NSDictionary alloc] initWithObjectsAndKeys:(id)kCFBooleanTrue, kCGImageSourceCreateThumbnailWithTransform, kCFBooleanTrue, kCGImageSourceCreateThumbnailFromImageAlways, [NSNumber numberWithDouble:300], kCGImageSourceThumbnailMaxPixelSize, nil];
#if KONOTOR_IMG_COMPRESSION
        NSDictionary *compressionOptions = [[NSDictionary alloc] initWithObjectsAndKeys:(id)kCFBooleanTrue, kCGImageSourceCreateThumbnailWithTransform, kCFBooleanTrue, kCGImageSourceCreateThumbnailFromImageAlways, [NSNumber numberWithDouble:1000], kCGImageSourceThumbnailMaxPixelSize, nil];
#endif
        
        CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(src, 0, (__bridge CFDictionaryRef)osptions); // Create scaled image
        
#if KONOTOR_IMG_COMPRESSION
        CGImageRef compressedImage = CGImageSourceCreateThumbnailAtIndex(src, 0, (__bridge CFDictionaryRef)compressionOptions);
#endif
        
        UIImage *imgthumb = [[UIImage alloc] initWithCGImage:thumbnail];
        
#if KONOTOR_IMG_COMPRESSION
        UIImage *imgCompressed = [[UIImage alloc] initWithCGImage:compressedImage];
#endif
        
        thumbnailData = UIImageJPEGRepresentation(imgthumb,0.5);
        
#if KONOTOR_IMG_COMPRESSION
        imageData=UIImageJPEGRepresentation(imgCompressed, 0.5);
        imageWidth = imgCompressed.size.width;
        imageHeight = imgCompressed.size.height;
#else
        imageWidth = image.size.width;
        imageHeight = image.size.height;
#endif
        imageThumbHeight = imgthumb.size.height;
        imageThumbWidth = imgthumb.size.width;
        
        CFRelease(src);
        CFRelease(thumbnail);
        
        NSDictionary *thumbnailInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
                                       @"image/png",@"contentType",
                                       @"",@"content",
                                       [NSNumber numberWithFloat:imageThumbWidth],@"width",
                                       [NSNumber numberWithFloat:imageThumbHeight],@"height",
                                       nil];
        
        NSDictionary *imageFragmentInfo = [[NSDictionary alloc] initWithObjectsAndKeys:  @2, @"fragmentType",
                                           @"image/png",@"contentType",
                                           @"",@"content", //Populate with empty url
                                           [NSNumber numberWithFloat:imageWidth],@"width",
                                           [NSNumber numberWithFloat:imageHeight],@"height",
                                           imageData, @"binaryData1",
                                           thumbnailData, @"binaryData2",
                                           @0,@"position",
                                           thumbnailInfo, @"thumbnail",nil];
        
        [fragmentsInfo addObject: imageFragmentInfo];
    }
    
    if(![caption isEqualToString:@""]) {
        NSDictionary *textFragmentInfo = [[NSDictionary alloc] initWithObjectsAndKeys:  @1, @"fragmentType",
                                          @"text/html",@"contentType",
                                          caption,@"content",
                                          (image != nil) ? @1 : @0 ,@"position",nil];
        [fragmentsInfo addObject:textFragmentInfo];
    }
    
    Message *message = [Message saveMessageInCoreData:fragmentsInfo onConversation:conversation];
    [channel addMessagesObject:message];
    [[KonotorDataManager sharedInstance]save];
    
    if(![HLUser isUserRegistered]) {
        [HLUser registerUser:^(NSError *error) {
            if(!error) {
                [self uploadMessage:message withImage:image inChannel:channel andConversation:conversation];
            } else {
                [HLMessageServices markUploadFailedAndSaveMessage:message inChannel:channel];
            }
        }];
    } else {
        [self uploadMessage:message withImage:image inChannel:channel andConversation:conversation];
    }

}

+ (void) uploadMessage :(Message *) message withImage:(UIImage*)image inChannel:(HLChannel *) channel andConversation : (KonotorConversation *)conversation {
    [Konotor performSelector:@selector(UploadFinishedNotification:) withObject:message.messageAlias];
    if(image){
        [HLMessageServices uploadPictureMessage:message toConversation:conversation withCompletion:^{
            [HLMessageServices uploadNewMessage:message toConversation:conversation onChannel:channel];
            [[Konotor delegate] didStartUploadingNewMessage];
        }];
    }
    else{
        [HLMessageServices uploadNewMessage:message toConversation:conversation onChannel:channel];
        [[Konotor delegate] didStartUploadingNewMessage];
    }
}


+(void) uploadMessageWithImage:(UIImage *)image textFeed:(NSString *)textFeedback onConversation:(KonotorConversation *)conversation andChannel:(HLChannel *)channel{
    [HLUser setUserMessageInitiated];
    [self uploadNewMsgWithImage:image textFeed:textFeedback onConversation:conversation andChannel:channel];
}

+(void)uploadImage:(UIImage *)image onConversation:(KonotorConversation *)conversation onChannel:(HLChannel *)channel{
    [self uploadImage:image withCaption:nil onConversation:conversation onChannel:channel];
}

+(void) uploadImage:(UIImage *)image withCaption:(NSString *)caption onConversation:(KonotorConversation *)conversation onChannel:(HLChannel *)channel{
    
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

+(BOOL)isCurrentUser:(NSNumber *)userId{
    return [userId  isEqual: USER_TYPE_MOBILE];
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

+(void)NotifyServerError
{
    if([Konotor delegate])
    {
        if([[Konotor delegate] respondsToSelector:@selector(didNotifyServerError)])
        {
            [[Konotor delegate] didNotifyServerError];
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
        if([[Konotor delegate] respondsToSelector:@selector(didEncounterErrorWhileDownloadingConversations)])
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
