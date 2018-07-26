//
//  KonotorAudioRecorder.h
//  Konotor
//
//  Created by Vignesh G on 11/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "FCMessageUtil.h"

@interface FCAudioRecorder : AVAudioRecorder <UIAlertViewDelegate, AVAudioRecorderDelegate>
@property   (strong) NSURL *pFileDest;
@property (strong) NSNumber *duration;
@property (strong) NSString *messageID;
@property (strong ) NSString *textFeedback;

+(BOOL) startRecording;
+(BOOL) isRecording;
+(NSString *) stopRecording;
+(NSString *) stopRecordingOnConversation:(FCConversations*)conversation;
+(BOOL) cancelRecording;
+(BOOL) SendRecordingWithMessageID:(NSString *)messageID;
+(BOOL) SendRecordingWithMessageID:(NSString *)messageID toConversationID:(NSString *) conversationID onChannel:(FCChannels*)channel;
+ (NSTimeInterval) getTimeElapsedSinceStartOfRecording;
+(float) getDecibelLevel;
@end


@interface KonotorAlertView : UIAlertView

@property (strong) FCConversations *conversation;
@property (strong) FCMessageUtil *messageToBeSent;
@property (strong) FCChannels* channel;

@end


