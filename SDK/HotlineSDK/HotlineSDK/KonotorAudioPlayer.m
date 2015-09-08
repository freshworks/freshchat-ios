//
//  KonotorAudioPlayer.m
//  Konotor
//
//  Created by Vignesh G on 16/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import "KonotorAudioPlayer.h"
#import "KonotorUtil.h"
#import <UIKit/UIResponder.h>
#import <UIKit/UIApplication.h>
#import "Konotor.h"
@implementation KonotorAudioPlayer

KonotorMessage *gCurrentlyPlaying;

BOOL gkIsAudioAlreadyPlaying = NO;
KonotorAudioPlayer *gkSingletonPlayer = nil;

+(BOOL) playMessageWithMessageID : (NSString *)messageID
{
    return [KonotorAudioPlayer PlayMessage:messageID atTime:0];
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
    
    [KonotorAudioPlayer UnInitPlayer];
    
    [KonotorAudioPlayer currentPlaying:nil set:YES];
    return YES;
}

+(BOOL) PlayMessage : (NSString *)messageID atTime : (double) seektime
{
    
    
    
    NSError *error;
    KonotorMessage *messageObject = [KonotorMessage RetriveMessageForMessageId:messageID];
    if(!messageObject)
        return NO;
    
    AVAudioSession * audioSession = [AVAudioSession sharedInstance];
    
    //Activate the session
    
    
    [audioSession setActive:YES error:&error];
    
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error: &error];
    
    UInt32 allowBluetoothInput = 1;
    AudioSessionSetProperty (
                             kAudioSessionProperty_OverrideCategoryEnableBluetoothInput,
                             sizeof (allowBluetoothInput),
                             &allowBluetoothInput
                             );
    
    
    UInt32 routeSize = sizeof (CFStringRef);
    CFStringRef route;
    
    OSStatus stat = AudioSessionGetProperty (kAudioSessionProperty_AudioRoute,
                                             &routeSize,
                                             &route);
    
    NSString *stringRoute = (__bridge NSString *)(route);
    
    if(!stat)
    {
        if(!([stringRoute isEqualToString:@"HeadphonesAndMicrophone"]||[stringRoute isEqualToString:@"HeadsetInOut"]||[stringRoute isEqualToString:@"HeadsetBT"]))
        {
            //TODO
            //[(AppDelegate*)[[UIApplication sharedApplication] delegate] turnSpeakerOn:((AppDelegate*)[[UIApplication sharedApplication] delegate]).speakerOn];
        }
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
    
    KonotorMessageBinary *pMessageBinary = (KonotorMessageBinary*)[messageObject valueForKeyPath:@"hasMessageBinary"];
    
    NSData *soundData = [pMessageBinary binaryAudio];
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    
    if(!soundData)// if not in store download from
    {
        
        [KonotorAudioPlayer SaveAndPlayMessage:messageObject];
        
        [[KonotorAudioPlayer class] performSelectorInBackground:@selector(DownloadMessage:) withObject:messageObject];
        
    }
    
    else
    {
        [KonotorAudioPlayer currentPlaying:[gCurrentlyPlaying messageAlias] set:YES];
        BOOL playing=[KonotorAudioPlayer InitAndPlayWithSoundData:soundData];
        if(!playing)
            [KonotorAudioPlayer currentPlaying:nil set:YES] ;
        //return YES;
    }
    
    
    
    return YES;
    
}

+(void) UnInitPlayer
{
    
    AudioSessionSetActiveWithFlags (
                                    false,
                                    AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                    );
    
}

+(void) HandleDownloadExpiry:(id) parameter
{
    return;
}

+(void) DownloadMessage : (KonotorMessage *)messageObject
{
    
    UIBackgroundTaskIdentifier bgtask = [KonotorUtil beginBackgroundExecutionWithExpirationHandler:@selector(HandleDownloadExpiry:) withParameters:nil forObject:[KonotorAudioPlayer class]];
    
    
    if([messageObject isDownloading])
        return;
    NSURL *pURL = [NSURL URLWithString:[messageObject audioURL]];
   
    
    NSString *notifSString = [NSString stringWithFormat:@"%@_%@",[messageObject messageAlias],@"started"];
    NSNotification* notif=[NSNotification notificationWithName:notifSString object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notif];
    
    [KonotorNetworkUtil SetNetworkActivityIndicator:YES];
    NSData *soundData = [NSData dataWithContentsOfURL:pURL];
    [KonotorNetworkUtil SetNetworkActivityIndicator:NO];
    
    
    if(soundData)
    {
        
        
        NSString *notifString = [NSString stringWithFormat:@"%@_%@",[messageObject messageAlias],@"downloaded"];
        
        NSNotification* not=[NSNotification notificationWithName:notifString object:soundData];
        [[NSNotificationCenter defaultCenter] postNotification:not];
    }
    
    else
    {
        [Konotor performSelector:@selector(MediaDownloadFailedNotification:) withObject:
         messageObject.messageAlias];
        
        NSString *notifString = [NSString stringWithFormat:@"%@_%@",[messageObject messageAlias],@"failed"];
        
        NSNotification* not=[NSNotification notificationWithName:notifString object:nil];
        [[NSNotificationCenter defaultCenter] postNotification:not];
    }
    
    [KonotorUtil EndBackgroundExecutionForTask:bgtask];
}

+(BOOL) InitAndPlayWithSoundData : (NSData *)soundData
{
    NSError *pError;
    
    KonotorAudioPlayer *audioPlayer = [[KonotorAudioPlayer alloc]initWithData:soundData  error:&pError];
    gkSingletonPlayer = audioPlayer;
    audioPlayer.delegate=gkSingletonPlayer;
    
    
    if(![audioPlayer play])
    {
        [KonotorUtil AlertView:@"error playing audio" FromModule:@"Audio Player"];
        return NO;
    }
    
    [[ UIApplication sharedApplication ] setIdleTimerDisabled: YES ];
    
   NSString *messageid = [KonotorAudioPlayer currentPlaying:nil set:NO];
    
    [Konotor performSelector:@selector(MediaStartedNotification:) withObject:
     messageid];
    
    gkIsAudioAlreadyPlaying = YES;
    
    return YES;
    
}

+(NSString*) currentPlaying:(NSString*) mediaIDToSet set:(BOOL)toSet
{
    static NSString *mediaID=nil;
    if(toSet)
        mediaID=mediaIDToSet;
    return mediaID;
}



+(BOOL) SaveAndPlayMessage : (KonotorMessage *) messageObject
{
    
    
    NSString *successNotifString = [NSString stringWithFormat:@"%@_%@",[messageObject messageAlias],@"downloaded"];
    NSString *failedNotifString = [NSString stringWithFormat:@"%@_%@",[messageObject messageAlias],@"failed"];
    NSString *downloadstarted = [NSString stringWithFormat:@"%@_%@",[messageObject messageAlias],@"started"];
    
    NSManagedObjectContext *context = [[KonotorDataManager sharedInstance] mainObjectContext];
    
    __block id failobserver;
    __block id downloadstartedbserver;
    __block id successobserver = [[NSNotificationCenter defaultCenter] addObserverForName:successNotifString object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note)
          {
              
              
              NSError *pError;
              
              KonotorMessageBinary *messageBinary = (KonotorMessageBinary *)[NSEntityDescription insertNewObjectForEntityForName:@"KonotorMessageBinary" inManagedObjectContext:context];
              [messageBinary setBinaryAudio:[note object]];
              
              [messageObject setValue:messageBinary forKey:@"hasMessageBinary"];
              [messageObject setIsDownloading:NO];
              
              [context save:&pError];
              
              if(messageObject == gCurrentlyPlaying) // in the meanwhile the user could have clicked on another message, thats why check if this the last messaged to be asked to be played.
              {
                  [KonotorAudioPlayer currentPlaying:[gCurrentlyPlaying messageAlias] set:YES];

                  BOOL playing=[KonotorAudioPlayer InitAndPlayWithSoundData:[note object]];
                  if(!playing)
                      [KonotorAudioPlayer currentPlaying:nil set:YES];

              }
              
              [[NSNotificationCenter defaultCenter] removeObserver:successobserver];
              [[NSNotificationCenter defaultCenter] removeObserver:failobserver];
              
              
          }
          
          ];

        failobserver = [[NSNotificationCenter defaultCenter] addObserverForName:failedNotifString object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note)
        {
            NSError *pError;

            [messageObject setIsDownloading:NO];
            [context save:&pError];

            //Have to notify kottayan that download has failed.
            [[NSNotificationCenter defaultCenter] removeObserver:successobserver];
            [[NSNotificationCenter defaultCenter] removeObserver:failobserver];


        }

        ];

        downloadstartedbserver = [[NSNotificationCenter defaultCenter] addObserverForName:downloadstarted object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note)
        {
          NSError *pError;
          
          [messageObject setIsDownloading:YES];
          [context save:&pError];
          [[NSNotificationCenter defaultCenter] removeObserver:downloadstartedbserver];
          
          
        }

        ];
    
    return YES;
}

//bool gAudioAudioOverride = true;





+(BOOL) StopMessage : (KonotorMessage *)messageObject;
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
    
    [KonotorAudioPlayer UnInitPlayer];
    
    [KonotorAudioPlayer currentPlaying:nil set:YES];
    
    NSNotification* not=[NSNotification notificationWithName:@"MediaFinished" object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:not];
    
    return YES;
}


- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSString *messageid = [KonotorAudioPlayer currentPlaying:nil set:NO];
    
    [Konotor performSelector:@selector(messageFinishedPlayingNotification:) withObject:
     messageid];
    
    gkSingletonPlayer = nil;
    gkIsAudioAlreadyPlaying = NO;
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
    
    [[ UIApplication sharedApplication ] setIdleTimerDisabled: NO ];
    
    [KonotorAudioPlayer UnInitPlayer];
    [KonotorAudioPlayer currentPlaying:nil set:YES];

    
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
        [KonotorAudioPlayer StopMessage:gCurrentlyPlaying];
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
