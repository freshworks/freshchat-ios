//
//  FDAudioMessageUnit.m
//  HotlineSDK
//
//  Created by Srikrishnan Ganesan on 27/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FCAudioMessageUnit.h"
#import "FCTheme.h"
#import "FCAudioRecorder.h"
#import "FCLocalization.h"
#import "FCLocalNotification.h"

#define KONOTOR_HORIZONTAL_PADDING 5
#define KONOTOR_TEXTMESSAGE_MAXWIDTH 260.0
#define KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING 10

@interface FCAudioMessageUnit ()

@property (nonatomic, strong)FCTheme *theme;

@end

@implementation FCAudioMessageUnit

@synthesize mediaProgressBar,messageID,progressAnimationTimer,message,audioPlayButton,playbackState;

- (instancetype)init{
    self = [super init];
    if (self) {
        self.theme = [FCTheme sharedInstance];
    }
    return self;
}

- (void) startAnimating
{
    playbackState=FDAudioMessageMediaStatePlaying;
    progressAnimationTimer= [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
    [audioPlayButton setImage:[self.theme getImageWithKey:IMAGE_AUDIO_STOP_BUTTON] forState:UIControlStateNormal];
    [progressAnimationTimer fire];
}

- (void) updateProgress
{
  /* To Be fixed once we get the right client API here */
   if([messageID isEqualToString:[FCMessageHelper getCurrentPlayingMessageID]])
        [mediaProgressBar setValue:[FCMessageHelper getCurrentPlayingAudioTime] animated:NO];
    else
        [self stopAnimating];
}

- (void) stopAnimating
{
    playbackState=FDAudioMessageMediaStateStopped;
    [progressAnimationTimer invalidate];
    [audioPlayButton setImage:[self.theme getImageWithKey:IMAGE_AUDIO_PLAY_BUTTON] forState:UIControlStateNormal];
    progressAnimationTimer=nil;
    [mediaProgressBar setValue:0 animated:NO];
}

-(void) setHidden:(BOOL)hidden
{
    [audioPlayButton setHidden:hidden];
    [mediaProgressBar setHidden:hidden];
}

-(void) setUpView
{
    float messageTextBoxWidth=KONOTOR_TEXTMESSAGE_MAXWIDTH-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING*2;
    self.audioPlayButton=[[UIButton alloc] initWithFrame:CGRectMake(KONOTOR_HORIZONTAL_PADDING/2,KONOTOR_AUDIOMESSAGE_HEIGHT/2-KONOTOR_PLAYBUTTON_DIMENSION/2,KONOTOR_PLAYBUTTON_DIMENSION,KONOTOR_PLAYBUTTON_DIMENSION)];
    [self.audioPlayButton setImage:[self.theme getImageWithKey:IMAGE_AUDIO_PLAY_BUTTON] forState:UIControlStateNormal];

    [self.audioPlayButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.audioPlayButton addTarget:self action:@selector(playMedia:) forControlEvents:UIControlEventTouchUpInside];
    
    self.mediaProgressBar=[[UISlider alloc] initWithFrame:CGRectMake(KONOTOR_HORIZONTAL_PADDING/2+KONOTOR_PLAYBUTTON_DIMENSION, KONOTOR_AUDIOMESSAGE_HEIGHT/2-1, messageTextBoxWidth-KONOTOR_PLAYBUTTON_DIMENSION-3*KONOTOR_HORIZONTAL_PADDING, 2)];
    [self.mediaProgressBar setThumbImage:[UIImage new] forState:UIControlStateNormal];
    
    [self.mediaProgressBar setMinimumTrackImage:[self.theme getImageWithKey:IMAGE_AUDIO_PROGRESS_BAR_MIN] forState:UIControlStateNormal];
    [self.mediaProgressBar setMaximumTrackImage:[self.theme getImageWithKey:IMAGE_AUDIO_PROGRESS_BAR_MAX] forState:UIControlStateNormal];
    
    UILongPressGestureRecognizer* longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(progressLongPress:)];
    [longPressGesture setMinimumPressDuration:0.50];
    longPressGesture.delegate =self;
    [mediaProgressBar addGestureRecognizer:longPressGesture];
}

-(void)progressLongPress:(UILongPressGestureRecognizer*)recognizer
{
    // disable long press
}

-(void) playMedia:(id)sender
{
    
    if([FCAudioRecorder isRecording]){
        UIAlertView *actionAlert = [[UIAlertView alloc] initWithTitle:HLLocalizedString(LOC_AUDIO_RECORDING_CANCEL_MESSAGE) message:nil delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        [actionAlert show];
    }
    else{
        [self playAudioMessage];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        //Donot do any thing ....
    }
    else
    {
        [FCLocalNotification post:HOTLINE_AUDIO_RECORDING_CLOSE];
    }
}

- (void) playAudioMessage{
    
    if([[FCMessageHelper getCurrentPlayingMessageID] isEqualToString:self.messageID])
    {
        [FCMessageHelper StopPlayback];
        return;
    }
    BOOL playing=[FCMessageHelper playMessageWithMessageID:self.messageID];
    if(playing)
        [self startAnimating];
}

- (void) displayMessage:(KonotorMessageData*) currentMessage
{
    /*[self.audioPlayButton setHidden:NO];
    [self.mediaProgressBar setHidden:NO];
    
    self.messageID=[currentMessage messageID];
    self.message=(FDMessage*)currentMessage;
    
    [self.mediaProgressBar setValue:0.0 animated:NO];
    [self.mediaProgressBar setMaximumValue:currentMessage.durationInSecs.floatValue];
    if([[Konotor getCurrentPlayingMessageID] isEqualToString:[currentMessage messageId]])
        [self startAnimating];*/
}


@end
