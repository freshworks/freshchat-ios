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
 /*  if([messageID isEqualToString:[Konotor getCurrentPlayingMessageID]])
        [mediaProgressBar setValue:[Konotor getCurrentPlayingAudioTime] animated:NO];
    else
        [self stopAnimating];*/
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

@end
