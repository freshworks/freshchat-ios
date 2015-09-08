//
//  KonotorMediaUIButton.m
//  KonotorDemo
//
//  Created by Srikrishnan Ganesan on 11/08/13.
//  Copyright (c) 2013 Demach. All rights reserved.
//

#import "KonotorMediaUIButton.h"

@implementation KonotorMediaUIButton

@synthesize mediaProgressBar,messageID,progressAnimationTimer,buttonState;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) startAnimating
{
    buttonState=KonotorMediaUIButtonStatePlaying;
    progressAnimationTimer= [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
    [self setImage:[UIImage imageNamed:@"konotor_stop"] forState:UIControlStateNormal];
    [progressAnimationTimer fire];
}

- (void) updateProgress
{
    if([messageID isEqualToString:[Konotor getCurrentPlayingMessageID]])
        [mediaProgressBar setValue:[Konotor getCurrentPlayingAudioTime] animated:NO];
    else
        [self stopAnimating];
}

- (void) stopAnimating
{
    buttonState=KonotorMediaUIButtonStateStopped;
    [progressAnimationTimer invalidate];
    [self setImage:[UIImage imageNamed:@"konotor_play"] forState:UIControlStateNormal];
    progressAnimationTimer=nil;
    [mediaProgressBar setValue:0 animated:NO];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
