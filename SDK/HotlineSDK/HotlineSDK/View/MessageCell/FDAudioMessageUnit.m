//
//  FDAudioMessageUnit.m
//  HotlineSDK
//
//  Created by Srikrishnan Ganesan on 27/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDAudioMessageUnit.h"
#import "HLTheme.h"

@interface FDAudioMessageUnit ()

@property (nonatomic, strong)HLTheme *theme;

@end

@implementation FDAudioMessageUnit

@synthesize mediaProgressBar,messageID,progressAnimationTimer,message,audioPlayButton,playbackState;

- (instancetype)init{
    self = [super init];
    if (self) {
        self.theme = [HLTheme sharedInstance];
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
   if([messageID isEqualToString:[Konotor getCurrentPlayingMessageID]])
        [mediaProgressBar setValue:[Konotor getCurrentPlayingAudioTime] animated:NO];
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
//    [self.audioPlayButton setBackgroundColor:[UIColor blackColor]];
//    self.audioPlayButton.layer.cornerRadius=KONOTOR_PLAYBUTTON_DIMENSION/2;
    [self.audioPlayButton addTarget:self action:@selector(playMedia:) forControlEvents:UIControlEventTouchUpInside];
    
    self.mediaProgressBar=[[UISlider alloc] initWithFrame:CGRectMake(KONOTOR_HORIZONTAL_PADDING/2+KONOTOR_PLAYBUTTON_DIMENSION, KONOTOR_AUDIOMESSAGE_HEIGHT/2-1, messageTextBoxWidth-KONOTOR_PLAYBUTTON_DIMENSION-3*KONOTOR_HORIZONTAL_PADDING, 2)];
    [self.mediaProgressBar setThumbImage:[UIImage imageNamed:@"konotor_progress_black"] forState:UIControlStateNormal];
  //  self.mediaProgressBar.frame=CGRectMake(KONOTOR_HORIZONTAL_PADDING, KONOTOR_AUDIOMESSAGE_HEIGHT/2-self.mediaProgressBar.currentThumbImage.size.height/2, messageTextBoxWidth-KONOTOR_PLAYBUTTON_DIMENSION-3*KONOTOR_HORIZONTAL_PADDING, self.mediaProgressBar.currentThumbImage.size.height);
  //  self.mediaProgressBar.frame=CGRectMake(KONOTOR_HORIZONTAL_PADDING, KONOTOR_AUDIOMESSAGE_HEIGHT/2-self.mediaProgressBar.bounds.size.height/2, messageTextBoxWidth-KONOTOR_PLAYBUTTON_DIMENSION-3*KONOTOR_HORIZONTAL_PADDING, self.mediaProgressBar.bounds.size.height);
    
    [self.mediaProgressBar setMinimumTrackImage:[self.theme getImageWithKey:IMAGE_AUDIO_PROGRESS_BAR_MIN] forState:UIControlStateNormal];
    [self.mediaProgressBar setMaximumTrackImage:[self.theme getImageWithKey:IMAGE_AUDIO_PROGRESS_BAR_MAX] forState:UIControlStateNormal];
}

-(void) playMedia:(id)sender
{
    if([[Konotor getCurrentPlayingMessageID] isEqualToString:self.messageID])
    {
        [Konotor StopPlayback];
        return;
    }
    BOOL playing=[Konotor playMessageWithMessageID:self.messageID];
    if(playing)
       [self startAnimating];
}

- (void) displayMessage:(KonotorMessageData*) currentMessage
{
    [self.audioPlayButton setHidden:NO];
    [self.mediaProgressBar setHidden:NO];
    
    self.messageID=[currentMessage messageId];
    self.message=(FDMessage*)currentMessage;
    
    [self.mediaProgressBar setValue:0.0 animated:NO];
    [self.mediaProgressBar setMaximumValue:currentMessage.durationInSecs.floatValue];
    if([[Konotor getCurrentPlayingMessageID] isEqualToString:[currentMessage messageId]])
        [self startAnimating];
}


@end
