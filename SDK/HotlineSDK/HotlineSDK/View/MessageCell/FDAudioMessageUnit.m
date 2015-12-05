//
//  FDAudioMessageUnit.m
//  HotlineSDK
//
//  Created by Srikrishnan Ganesan on 27/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDAudioMessageUnit.h"

@implementation FDAudioMessageUnit

@synthesize mediaProgressBar,messageID,progressAnimationTimer,message,audioPlayButton,playbackState;


- (void) startAnimating
{
    playbackState=FDAudioMessageMediaStatePlaying;
    progressAnimationTimer= [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
    [audioPlayButton setImage:[UIImage imageNamed:@"konotor_stop"] forState:UIControlStateNormal];
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
    [audioPlayButton setImage:[UIImage imageNamed:@"konotor_play"] forState:UIControlStateNormal];
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
    float messageTextBoxWidth=KONOTOR_TEXTMESSAGE_MAXWIDTH-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING;
    self.audioPlayButton=[[UIButton alloc] initWithFrame:CGRectMake(messageTextBoxWidth-KONOTOR_HORIZONTAL_PADDING-KONOTOR_PLAYBUTTON_DIMENSION,KONOTOR_AUDIOMESSAGE_HEIGHT/2-KONOTOR_PLAYBUTTON_DIMENSION/2,KONOTOR_PLAYBUTTON_DIMENSION,KONOTOR_PLAYBUTTON_DIMENSION)];
    [self.audioPlayButton setImage:[UIImage imageNamed:@"konotor_play.png"] forState:UIControlStateNormal];
    [self.audioPlayButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.audioPlayButton setBackgroundColor:[UIColor blackColor]];
    self.audioPlayButton.layer.cornerRadius=KONOTOR_PLAYBUTTON_DIMENSION/2;
    [self.audioPlayButton addTarget:self action:@selector(playMedia:) forControlEvents:UIControlEventTouchUpInside];
    
    self.mediaProgressBar=[[UISlider alloc] initWithFrame:CGRectMake(KONOTOR_HORIZONTAL_PADDING, KONOTOR_AUDIOMESSAGE_HEIGHT/2-2, messageTextBoxWidth-KONOTOR_PLAYBUTTON_DIMENSION, 4)];
    self.mediaProgressBar.frame=CGRectMake(KONOTOR_HORIZONTAL_PADDING, KONOTOR_AUDIOMESSAGE_HEIGHT/2-self.mediaProgressBar.currentThumbImage.size.height/2, messageTextBoxWidth-KONOTOR_PLAYBUTTON_DIMENSION-3*KONOTOR_HORIZONTAL_PADDING, self.mediaProgressBar.currentThumbImage.size.height);
    self.mediaProgressBar.frame=CGRectMake(KONOTOR_HORIZONTAL_PADDING, KONOTOR_AUDIOMESSAGE_HEIGHT/2-self.mediaProgressBar.bounds.size.height/2, messageTextBoxWidth-KONOTOR_PLAYBUTTON_DIMENSION-3*KONOTOR_HORIZONTAL_PADDING, self.mediaProgressBar.bounds.size.height);
    
    [self.mediaProgressBar setMinimumTrackImage:[UIImage imageNamed:@"konotor_progress_blue.png"] forState:UIControlStateNormal];
    [self.mediaProgressBar setMaximumTrackImage:[UIImage imageNamed:@"konotor_progress_black.png"] forState:UIControlStateNormal];
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
