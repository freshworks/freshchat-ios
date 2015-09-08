//
//  KonotorAudioRecorder.h
//  Konotor
//
//  Created by Vignesh G on 11/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "KonotorUser.h"
#import "KonotorMessage.h"

@interface KonotorAudioRecorder : AVAudioRecorder <UIAlertViewDelegate, AVAudioRecorderDelegate>
@property   (strong) NSURL *pFileDest;
@property (strong) NSNumber *duration;
@property (strong) NSString *messageID;
@property (strong ) NSString *textFeedback;

+(BOOL) startRecording;
+(NSString *) stopRecording;
+(BOOL) cancelRecording;
+(BOOL) SendRecordingWithMessageID:(NSString *)messageID;
+ (NSTimeInterval) getTimeElapsedSinceStartOfRecording;
+(float) getDecibelLevel;
@end


@interface KonotorAlertView : UIAlertView

@property (strong) KonotorConversation *conversation;
@property (strong) KonotorMessage *messageToBeSent;

@end