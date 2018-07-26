//
//  FDAudioMessageInputView.h
//  HotlineSDK
//
//  Created by user on 30/11/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FCButton.h"

@class FCAudioMessageInputView;

@protocol FDAudioInputDelegate <NSObject>

-(void)audioMessageInput:(FCAudioMessageInputView *)toolbar dismissButtonPressed:(id)sender;
-(void)audioMessageInput:(FCAudioMessageInputView *)toolbar sendButtonPressed:(id)sender;
-(void)audioMessageInput:(FCAudioMessageInputView *)toolbar stopButtonPressed:(id)sender;

@end

@interface FCAudioMessageInputView : UIView

@property (weak, nonatomic) id <FDAudioInputDelegate> delegate;

-(id)initWithDelegate:(id <FDAudioInputDelegate>)delegate;

@property (nonatomic,strong) UIButton *dismissButton;
@property (nonatomic,strong) UIButton *stopButton;
@property (nonatomic,strong) UIButton *sendButton;
@property (nonatomic,strong) UILabel *timeLabel;
@property (nonatomic,strong) UILabel *recordingLabel;

@end
