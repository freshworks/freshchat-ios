//
//  FDAudioMessageInputView.m
//  HotlineSDK
//
//  Created by user on 30/11/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDAudioMessageInputView.h"
#import "HLTheme.h"

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
        self.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
        
        self.dismissButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.dismissButton setImage:[UIImage imageNamed:@"cancel.png"] forState:UIControlStateNormal];
        [self.dismissButton addTarget:self action:@selector(dismissButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        self.dismissButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.dismissButton];
        
        self.stopButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.stopButton setImage:[UIImage imageNamed:@"stop.png"] forState:UIControlStateNormal];
        [self.stopButton addTarget:self action:@selector(stopButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        self.stopButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.stopButton];
        
        self.uploadButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.uploadButton.hidden = YES;
        [self.uploadButton setImage:[UIImage imageNamed:@"Upload.png"] forState:UIControlStateNormal];
        self.uploadButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.uploadButton];
        
        self.timeLabel = [[UILabel alloc] init];
        self.timeLabel.text = @"00:01";
        self.timeLabel.font = [[HLTheme sharedInstance] voiceRecordingTimeLabelFont];
        self.timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.timeLabel];
        
        self.recordingLabel = [[UILabel alloc] init];
        self.recordingLabel.text = @"Started Recording..";
        self.recordingLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.recordingLabel];
    }
    return self;
}

-(void)layoutSubviews{
    NSDictionary *views = @{@"dismissButton":self.dismissButton,@"stopButton":self.stopButton,@"uploadButton":self.uploadButton,@"timeLabel":self.timeLabel,@"recordingLabel":self.recordingLabel};
    
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
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[uploadButton]-|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[uploadButton]-|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[timeLabel]-[stopButton]" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[timeLabel]-|" options:0 metrics:nil views:views]];
    [super layoutSubviews];
}

-(void)startTimer{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

- (void)timerTick:(NSTimer *)timer{
    timeSec++;
    if (timeSec == 60){
        timeSec = 0;
        timeMin++;
    }
    NSString* timeNow = [NSString stringWithFormat:@"%02d:%02d", timeMin, timeSec];
    self.timeLabel.text= timeNow;
}

- (void) StopTimer{
    [self.timer invalidate];
    timeSec = 0;
    timeMin = 0;
    NSString* timeNow = [NSString stringWithFormat:@"%02d:%02d", timeMin, timeSec];
    self.timeLabel.text= timeNow;
}

-(void)stopButtonPressed:(id)sender{
    NSLog(@"Stop button pressed in audio input view");
    self.stopButton.hidden = YES;
    self.uploadButton.hidden = NO;
    self.recordingLabel.text = @"Recording Stopped";
}

-(void)dismissButtonAction:(id)sender{
    [self.delegate audioMessageInput:self dismissButtonPressed:sender];
}

@end