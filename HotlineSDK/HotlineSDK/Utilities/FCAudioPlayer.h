//
//  KonotorAudioPlayer.h
//  Konotor
//
//  Created by Vignesh G on 16/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "FCMessageUtil.h"
#import "FCMessageBinaries.h"
#import "FCDataManager.h"
#import <UIKit/UIApplication.h>

@interface FCAudioPlayer : AVAudioPlayer <AVAudioPlayerDelegate>
+(BOOL) StopMessage;
+(BOOL) playMessageWithMessageID:(NSString *)messageID;
+(BOOL) PlayMessage : (NSString *)messageID atTime : (double) seektime;
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag;
+ (double) audioPlayerGetCurrentTime;
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error;
+(NSString*) currentPlaying:(NSString*) mediaIDToSet set:(BOOL)toSet;
#if TARGET_OS_IPHONE

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player;
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withOptions:(NSUInteger)flags NS_AVAILABLE_IOS(6_0);
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withFlags:(NSUInteger)flags NS_DEPRECATED_IOS(4_0, 6_0);
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player NS_DEPRECATED_IOS(2_2, 6_0);
+ (double) audioPlayerGetFullTime;
#endif

@end
