
//
//  Konotor.m
//  Konotor
//
//  Created by Vignesh G on 04/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import "FCMessageHelper.h"
#import "FCDataManager.h"
#import "FCAudioRecorder.h"
#import "FCAudioPlayer.h"
#import "FCMacros.h"
#import "FCMessageServices.h"
#import "FCUtilities.h"
#import "FCSecureStore.h"
#import <ImageIO/ImageIO.h>
#import "FCUserUtil.h"

#import "FCMessages.h"

#define KONOTOR_IMG_COMPRESSION YES

@implementation FCMessageHelper

__weak static id <KonotorDelegate> _delegate;

+(id) delegate{
    return _delegate;
}

+(void) setDelegate:(id)delegate{
    _delegate = delegate;
}

+(double) getCurrentPlayingAudioTime
{
    return [FCAudioPlayer audioPlayerGetCurrentTime];
}

+(NSString *) stopRecording
{
    return[FCAudioRecorder stopRecording];
}

+(BOOL) isRecording{
    return [FCAudioRecorder isRecording];
}

+(NSString *) stopRecordingOnConversation:(FCConversations*)conversation
{
    return [FCAudioRecorder stopRecordingOnConversation:conversation];
}

+ (NSTimeInterval) getTimeElapsedSinceStartOfRecording
{
    return[FCAudioRecorder getTimeElapsedSinceStartOfRecording];

}

+(BOOL) cancelRecording
{
    return[FCAudioRecorder cancelRecording];

}

+(void) uploadVoiceRecordingWithMessageID: (NSString *)MessageID toConversationID: (NSString *)ConversationID onChannel:(FCChannels*)channel{
    [FCAudioRecorder SendRecordingWithMessageID:MessageID toConversationID:ConversationID onChannel:channel];
    [[FCMessageHelper delegate] didStartUploadingNewMessage];
}

+(BOOL) StopPlayback{
    return [FCAudioPlayer StopMessage];
}

+(NSString *)getCurrentPlayingMessageID{
    return [FCAudioPlayer currentPlaying:nil set:NO ];
}

+(void)uploadNewMessage:(NSArray *)fragmentsInfo onConversation:(FCConversations *)conversation onChannel:(FCChannels *)channel{
    FCMessages *message = [FCMessages saveMessageInCoreData:fragmentsInfo onConversation:conversation];
    [channel addMessagesObject:message];
    [[FCDataManager sharedInstance]save];
    [FCMessageServices uploadNewMessage:message toConversation:conversation onChannel:channel];    
    [[FCMessageHelper delegate] didStartUploadingNewMessage];
    
}

+(void)uploadNewMsgWithImage:(UIImage *)image textFeed:(NSString *)caption onConversation:(FCConversations *)conversation andChannel:(FCChannels *)channel{
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
    
    FCMessages *message = [FCMessages saveMessageInCoreData:fragmentsInfo onConversation:conversation];
    [channel addMessagesObject:message];
    [[FCDataManager sharedInstance]save];
    
    if(![FCUserUtil isUserRegistered]) {
        [FCUserUtil registerUser:nil];
    } else {
        [self uploadMessage:message withImage:image inChannel:channel andConversation:conversation];
    }

}

+ (void) uploadMessage :(FCMessages *) message withImage:(UIImage*)image inChannel:(FCChannels *) channel andConversation : (FCConversations *)conversation {
    [FCMessageHelper performSelector:@selector(UploadFinishedNotification:) withObject:message.messageAlias];
    if(image){
        [FCMessageServices uploadPictureMessage:message toConversation:conversation withCompletion:^{
            [FCMessageServices uploadNewMessage:message toConversation:conversation onChannel:channel];
            [[FCMessageHelper delegate] didStartUploadingNewMessage];
        }];
    }
    else{
        [FCMessageServices uploadNewMessage:message toConversation:conversation onChannel:channel];
        [[FCMessageHelper delegate] didStartUploadingNewMessage];
    }
}


+(void) uploadMessageWithImage:(UIImage *)image textFeed:(NSString *)textFeedback onConversation:(FCConversations *)conversation andChannel:(FCChannels *)channel{
    [FCUserUtil setUserMessageInitiated];
    [self uploadNewMsgWithImage:image textFeed:textFeedback onConversation:conversation andChannel:channel];
}

+(void)uploadImage:(UIImage *)image onConversation:(FCConversations *)conversation onChannel:(FCChannels *)channel{
    [self uploadImage:image withCaption:nil onConversation:conversation onChannel:channel];
}

+(void) uploadImage:(UIImage *)image withCaption:(NSString *)caption onConversation:(FCConversations *)conversation onChannel:(FCChannels *)channel{
    
    FCMessageUtil *message = [FCMessageUtil savePictureMessageInCoreData:image withCaption:caption onConversation:conversation];
    [channel addMessagesObject:message];
    [FCMessageServices uploadMessage:message toConversation:conversation onChannel:channel];
    [[FCMessageHelper delegate] didStartUploadingNewMessage];
}

+(BOOL) playMessageWithMessageID:(NSString *) messageID
{
    return [FCAudioPlayer playMessageWithMessageID:messageID];
    
}

+(BOOL) playMessageWithMessageID:(NSString *) messageID atTime:(double)time
{
    return [FCAudioPlayer PlayMessage:messageID atTime:time];
    
}

+(BOOL) setBinaryImage:(NSData *)imageData forMessageId:(NSString *)messageId
{
    return [FCMessageUtil setBinaryImage:imageData forMessageId:messageId];
}
+(BOOL) setBinaryImageThumbnail:(NSData *)imageData forMessageId:(NSString *)messageId
{
    return [FCMessageUtil setBinaryImageThumbnail:imageData forMessageId:messageId];
}

+(BOOL)isUserMe:(NSString *)userId{
    NSString *currentUserID = [USER_TYPE_MOBILE stringValue];
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
    if([FCMessageHelper delegate])
    {
        if([[FCMessageHelper delegate] respondsToSelector:@selector(didFinishDownloadingMessages) ])
        {
            [[FCMessageHelper delegate] didFinishDownloadingMessages];
        }
    }
}

+(void)UploadFinishedNotification: (NSString *) messageID{
    if([FCMessageHelper delegate]){
        if([[FCMessageHelper delegate] respondsToSelector:@selector(didFinishUploading:) ]){
            [[FCMessageHelper delegate] didFinishUploading:messageID];
        }
    }
}

+(void)UploadFailedNotification: (NSString *) messageID
{
    if([FCMessageHelper delegate])
    {
        if([[FCMessageHelper delegate] respondsToSelector:@selector(didEncounterErrorWhileUploading:) ])
        {
            [[FCMessageHelper delegate] didEncounterErrorWhileUploading:messageID];
        }
    }
}

+(void)NotifyServerError
{
    if([FCMessageHelper delegate])
    {
        if([[FCMessageHelper delegate] respondsToSelector:@selector(didNotifyServerError)])
        {
            [[FCMessageHelper delegate] didNotifyServerError];
        }
    }
}

+(void) MediaDownloadFailedNotification:(NSString *) messageID
{
    if([FCMessageHelper delegate])
    {
        if([[FCMessageHelper delegate] respondsToSelector:@selector(didEncounterErrorWhileDownloading:) ])
        {
            [[FCMessageHelper delegate] didEncounterErrorWhileDownloading:messageID];
        }
    }
}

+(void) conversationsDownloadFailed
{
    if([FCMessageHelper delegate])
    {
        if([[FCMessageHelper delegate] respondsToSelector:@selector(didEncounterErrorWhileDownloadingConversations)])
        {
            [[FCMessageHelper delegate] didEncounterErrorWhileDownloadingConversations];
        }
    }
}
@end
