//
//  FDAudioMessageInputView.m
//  HotlineSDK
//
//  Created by user on 30/11/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDAudioMessageInputView.h"
#import "HLTheme.h"
#import "Konotor.h"
#import "HLLocalization.h"

@interface FDAudioMessageInputView ()

@property (nonatomic,strong) NSTimer *timer;
@property (weak, nonatomic) id <FDAudioInputDelegate> delegate;
@property (nonatomic, strong) HLTheme *theme;

@end

@implementation FDAudioMessageInputView

int timeSec;
int timeMin;

-(id)initWithDelegate:(id <FDAudioInputDelegate>)delegate{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.theme = [HLTheme sharedInstance];
        self.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
        
        self.dismissButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.dismissButton setImage:[self.theme getImageWithKey:IMAGE_AUDIO_TOOLBAR_CANCEL] forState:UIControlStateNormal];
        [self.dismissButton addTarget:self action:@selector(dismissButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        self.dismissButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.dismissButton];
        
        self.stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.stopButton addTarget:self action:@selector(stopButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        self.stopButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.stopButton];
        
        self.sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.sendButton setImage:[self.theme getImageWithKey:IMAGE_SEND_ICON] forState:UIControlStateNormal];
        [self.sendButton addTarget:self action:@selector(sendButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        self.sendButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.sendButton];
        
        self.timeLabel = [[UILabel alloc] init];
        self.timeLabel.text = @"00:00";
        self.timeLabel.font = [[HLTheme sharedInstance] voiceRecordingTimeLabelFont];
        self.timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.timeLabel];
        
        self.recordingLabel = [[UILabel alloc] init];
        self.recordingLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.recordingLabel];
        
        [self resetAudioInputToolbar];
    }
    return self;
}

-(void)layoutSubviews{
    NSDictionary *views = @{@"dismissButton":self.dismissButton,@"stopButton":self.stopButton,@"sendButton":self.sendButton,@"timeLabel":self.timeLabel,@"recordingLabel":self.recordingLabel};
    
    [self addConstraint: [NSLayoutConstraint constraintWithItem:self.recordingLabel
                                  attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self
                                  attribute:NSLayoutAttributeCenterX  multiplier:1 constant:0]];
    
    [self addConstraint: [NSLayoutConstraint constraintWithItem:self.recordingLabel
                                  attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self
                                  attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[dismissButton]" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[dismissButton]-|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[stopButton]-|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[stopButton]-|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[sendButton]-|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[sendButton]-|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[timeLabel]-[stopButton]" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[timeLabel]-|" options:0 metrics:nil views:views]];
    [self startTimer];
    [super layoutSubviews];
}

-(void)startTimer{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

- (void)timerTick:(NSTimer *)timer{
    self.timeLabel.text= [NSString stringWithFormat:@"%02d:%02d",(int)[Konotor getTimeElapsedSinceStartOfRecording]/(int)60,(int)[Konotor getTimeElapsedSinceStartOfRecording]%(int)60];
}

- (void) StopTimer{
    [self.timer invalidate];
    self.timeLabel.text= [NSString stringWithFormat:@"%02d:%02d",(int)[Konotor getTimeElapsedSinceStartOfRecording]/(int)60,(int)[Konotor getTimeElapsedSinceStartOfRecording]%(int)60];
}

-(void)stopButtonPressed:(id)sender{
    self.stopButton.hidden = YES;
    self.sendButton.hidden = NO;
    self.recordingLabel.text = HLLocalizedString(LOC_AUDIO_RECORDING_STOPPED);
    [self StopTimer];
    [self.delegate audioMessageInput:self stopButtonPressed:sender];
}

-(void)dismissButtonAction:(id)sender{
    [self resetAudioInputToolbar];
    [self.delegate audioMessageInput:self dismissButtonPressed:sender];
}

-(void)sendButtonAction:(id)sender{
    [self resetAudioInputToolbar];
    [self.delegate audioMessageInput:self sendButtonPressed:sender];
}

-(void)resetAudioInputToolbar{
    self.stopButton.hidden = YES;
    self.sendButton.hidden = NO;
    self.recordingLabel.text = HLLocalizedString(LOC_AUDIO_RECORDING);
    self.recordingLabel.font      = [self.theme dialogueTitleFont];
    self.recordingLabel.textColor = [self.theme dialogueTitleTextColor];
}

@end