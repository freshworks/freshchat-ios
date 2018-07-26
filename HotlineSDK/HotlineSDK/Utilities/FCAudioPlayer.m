//
//  KonotorAudioPlayer.m
//  Konotor
//
//  Created by Vignesh G on 16/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import "FCAudioPlayer.h"
#import <UIKit/UIResponder.h>
#import <UIKit/UIApplication.h>
#import "FCMessageHelper.h"
#import "FCUtilities.h"
#import "FCMacros.h"
#import "FCLocalNotification.h"

@implementation FCAudioPlayer

FCMessageUtil *gCurrentlyPlaying;

BOOL gkIsAudioAlreadyPlaying = NO;
FCAudioPlayer *gkSingletonPlayer = nil;
static NSString *beforePlayCategory;

+(BOOL) playMessageWithMessageID : (NSString *)messageID
{
    return [FCAudioPlayer PlayMessage:messageID atTime:0];
}

+(BOOL) StopMessage
{
    
    if(gkIsAudioAlreadyPlaying)
    {
        if(gkSingletonPlayer)
        {
            [gkSingletonPlayer stop];
            gkSingletonPlayer = nil;
            gkIsAudioAlreadyPlaying = NO;
            [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
            [[ UIApplication sharedApplication ] setIdleTimerDisabled: NO ];
        }
        
    }
    
    [FCAudioPlayer UnInitPlayer];
    
    [FCAudioPlayer currentPlaying:nil set:YES];
    NSError *error;
    [[AVAudioSession sharedInstance] setCategory:beforePlayCategory error:&error];
    if(error){
        ALog(@"Failed to set audio %@ session category", beforePlayCategory);
        return NO;
    }
    [FCLocalNotification post:FRESHCHAT_DID_FINISH_PLAYING_AUDIO_MESSAGE];
    return YES;
}

+(BOOL) PlayMessage : (NSString *)messageID atTime : (double) seektime{
    
    [FCLocalNotification post:FRESHCHAT_WILL_PLAY_AUDIO_MESSAGE];
    
    NSError *error;
    FCMessageUtil *messageObject = [FCMessageUtil retriveMessageForMessageId:messageID];
    if(!messageObject)
        return NO;
    
    AVAudioSession * audioSession = [AVAudioSession sharedInstance];
    beforePlayCategory = audioSession.category;
    
    //TODO: set audio session back to the original state when dismissing msg controller
    
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,sizeof (audioRouteOverride),&audioRouteOverride);
    
    [audioSession setActive:YES error:&error];
    
    [audioSession setCategory:AVAudioSessionCategoryPlayback error: &error];
    if(error){
        ALog(@"Failed to set audio session category");
        return NO;
    }
    gCurrentlyPlaying = messageObject;
    
    if(gkIsAudioAlreadyPlaying)
    {
        if(gkSingletonPlayer)
        {
            [gkSingletonPlayer stop];
            gkSingletonPlayer = nil;
            gkIsAudioAlreadyPlaying = NO;
        }
        
    }
    
    FCMessageBinaries *pMessageBinary = (FCMessageBinaries*)[messageObject valueForKeyPath:@"hasMessageBinary"];
    
    NSData *soundData = [pMessageBinary binaryAudio];
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    
    if(!soundData)// if not in store download from
    {
        
        [FCAudioPlayer SaveAndPlayMessage:messageObject];
        
        [[FCAudioPlayer class] performSelectorInBackground:@selector(DownloadMessage:) withObject:messageObject];
        
    }
    
    else
    {
        [FCAudioPlayer currentPlaying:[gCurrentlyPlaying messageAlias] set:YES];
        BOOL playing=[FCAudioPlayer InitAndPlayWithSoundData:soundData];
        if(!playing)
            [FCAudioPlayer currentPlaying:nil set:YES] ;
        //return YES;
    }
    
    return YES;
    
}

+(void) UnInitPlayer{
    AudioSessionSetActiveWithFlags (
                                    false,
                                    AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                    );
}

+(void) HandleDownloadExpiry:(id) parameter
{
    return;
}

+(void) DownloadMessage : (FCMessageUtil *)messageObject{
    
    if([messageObject isDownloading])
        return;
    NSURL *pURL = [NSURL URLWithString:[messageObject audioURL]];
    
    NSString *messageDownloadStartedNotif = [NSString stringWithFormat:HOTLINE_AUDIO_MESSAGE_STARTED,[messageObject messageAlias]];
    [FCLocalNotification post:messageDownloadStartedNotif];
    
    ShowNetworkActivityIndicator();
    NSData *soundData = [NSData dataWithContentsOfURL:pURL];
    HideNetworkActivityIndicator();
    
    
    if(soundData){
        NSString *messagesDownloadCompleteNotif = [NSString stringWithFormat:HOTLINE_AUDIO_MESSAGE_DOWNLOADED,[messageObject messageAlias]];
        [FCLocalNotification post:messagesDownloadCompleteNotif];
    }
    
    else
    {
        [FCMessageHelper performSelector:@selector(MediaDownloadFailedNotification:) withObject:
         messageObject.messageAlias];
        
        NSString *messagesDownloadFailedNotif = [NSString stringWithFormat:HOTLINE_AUDIO_MESSAGE_FAILED,[messageObject messageAlias]];
        [FCLocalNotification post:messagesDownloadFailedNotif];
    }
    
}

+(BOOL) InitAndPlayWithSoundData : (NSData *)soundData{
    NSError *pError;
    
    FCAudioPlayer *audioPlayer = [[FCAudioPlayer alloc]initWithData:soundData  error:&pError];
    gkSingletonPlayer = audioPlayer;
    audioPlayer.delegate=gkSingletonPlayer;
    
    
    if(![audioPlayer play])
    {
        [FCUtilities AlertView:@"error playing audio" FromModule:@"Audio Player"];
        return NO;
    }
    
    [[ UIApplication sharedApplication ] setIdleTimerDisabled: YES ];
    
    gkIsAudioAlreadyPlaying = YES;
    
    return YES;
    
}

+(NSString*) currentPlaying:(NSString*) mediaIDToSet set:(BOOL)toSet{
    static NSString *mediaID=nil;
    if(toSet)
        mediaID=mediaIDToSet;
    return mediaID;
}

+(BOOL) SaveAndPlayMessage : (FCMessageUtil *) messageObject{
    
    NSString *successNotifString = [NSString stringWithFormat:HOTLINE_AUDIO_MESSAGE_DOWNLOADED,[messageObject messageAlias]];
    NSString *failedNotifString = [NSString stringWithFormat:HOTLINE_AUDIO_MESSAGE_FAILED,[messageObject messageAlias]];
    NSString *downloadstarted = [NSString stringWithFormat:HOTLINE_AUDIO_MESSAGE_STARTED,[messageObject messageAlias]];
    
    NSManagedObjectContext *context = [[FCDataManager sharedInstance] mainObjectContext];
    
    __block id failobserver;
    __block id downloadstartedbserver;
    __block id successobserver = [[NSNotificationCenter defaultCenter] addObserverForName:successNotifString object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note){
        
        NSError *pError;
        
        FCMessageBinaries *messageBinary = (FCMessageBinaries *)[NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_MESSAGE_BINARIES_ENTITY inManagedObjectContext:context];
        [messageBinary setBinaryAudio:[note object]];
        
        [messageObject setValue:messageBinary forKey:@"hasMessageBinary"];
        [messageObject setIsDownloading:NO];
        
        [context save:&pError];
        
        if(messageObject == gCurrentlyPlaying) // in the meanwhile the user could have clicked on another message, thats why check if this the last messaged to be asked to be played.
        {
            [FCAudioPlayer currentPlaying:[gCurrentlyPlaying messageAlias] set:YES];
            
            BOOL playing=[FCAudioPlayer InitAndPlayWithSoundData:[note object]];
            if(!playing)
                [FCAudioPlayer currentPlaying:nil set:YES];
            
        }
        
        [[NSNotificationCenter defaultCenter] removeObserver:successobserver];
        [[NSNotificationCenter defaultCenter] removeObserver:failobserver];
    }];
    
    failobserver = [[NSNotificationCenter defaultCenter] addObserverForName:failedNotifString object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note){
        NSError *pError;
        
        [messageObject setIsDownloading:NO];
        [context save:&pError];
        
        //Have to notify kottayan that download has failed.
        [[NSNotificationCenter defaultCenter] removeObserver:successobserver];
        [[NSNotificationCenter defaultCenter] removeObserver:failobserver];
        
        
    }];
    
    downloadstartedbserver = [[NSNotificationCenter defaultCenter] addObserverForName:downloadstarted object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note){
        NSError *pError;
        
        [messageObject setIsDownloading:YES];
        [context save:&pError];
        [[NSNotificationCenter defaultCenter] removeObserver:downloadstartedbserver];
    }];
    
    return YES;
}


+(BOOL) StopMessage : (FCMessageUtil *)messageObject;{
    if(gkIsAudioAlreadyPlaying)
    {
        if(gkSingletonPlayer)
        {
            [gkSingletonPlayer stop];
            gkSingletonPlayer = nil;
            gkIsAudioAlreadyPlaying = NO;
            [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
            [[ UIApplication sharedApplication ] setIdleTimerDisabled: NO ];
        }
    }
    
    [FCAudioPlayer UnInitPlayer];
    [FCAudioPlayer currentPlaying:nil set:YES];
    return YES;
}


- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    gkSingletonPlayer = nil;
    gkIsAudioAlreadyPlaying = NO;
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
    
    [[ UIApplication sharedApplication ] setIdleTimerDisabled: NO ];
    
    [FCAudioPlayer UnInitPlayer];
    [FCAudioPlayer currentPlaying:nil set:YES];
    
    NSError *error;
    [[AVAudioSession sharedInstance] setCategory:beforePlayCategory error:&error];
    if(error){
        ALog(@"Failed to set audio %@ play session category", beforePlayCategory);
    }
    [FCLocalNotification post:FRESHCHAT_DID_FINISH_PLAYING_AUDIO_MESSAGE];
}

+ (double) audioPlayerGetCurrentTime
{
    if(gkSingletonPlayer)
        return [gkSingletonPlayer currentTime];
    return 0;
}

+ (double) audioPlayerGetFullTime
{
    return [gkSingletonPlayer duration];
}

/* if an error occurs while decoding it will be reported to the delegate. */

+ (void) seekCurrentPlayingMessageToTime : (double) seekTime
{
    double duration = [gkSingletonPlayer duration];
    if(seekTime < duration)
    {
        [gkSingletonPlayer setCurrentTime:seekTime];
        [gkSingletonPlayer play];
    }
    
}


- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    //CBLog(@"Error did occur");
    double x = [gkSingletonPlayer currentTime];
    double duration = [gkSingletonPlayer duration];
    
    if(x+0.5< duration)
    {
        [gkSingletonPlayer setCurrentTime:x+0.5];
        [gkSingletonPlayer play];
    }
    
    else
    {
        [FCAudioPlayer StopMessage:gCurrentlyPlaying];
    }
    
    
}

#if TARGET_OS_IPHONE

/* audioPlayerBeginInterruption: is called when the audio session has been interrupted while the player was playing. The player will have been paused. */
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
    gkIsAudioAlreadyPlaying = NO;
}

/* audioPlayerEndInterruption:withFlags: is called when the audio session interruption has ended and this player had been interrupted while playing. */
/* Currently the only flag is AVAudioSessionInterruptionFlags_ShouldResume. */
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withFlags:(NSUInteger)flags NS_AVAILABLE_IOS(4_0)
{
    if([player play])
        gkIsAudioAlreadyPlaying = YES;
}
/* audioPlayerEndInterruption: is called when the preferred method, audioPlayerEndInterruption:withFlags:, is not implemented. */
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player
{
    return;
}

#endif // TARGET_OS_IPHONE

@end

