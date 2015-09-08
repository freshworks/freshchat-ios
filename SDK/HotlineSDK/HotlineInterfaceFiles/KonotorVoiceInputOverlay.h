//
//  KonotorVoiceInputOverlay.h
//  KonotorSampleApp
//
//  Created by Srikrishnan Ganesan on 13/07/13.
//  Copyright (c) 2013 Demach. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "KonotorUI.h"
#import "Konotor.h"


#define CONTAINER_RADIUS 80.0
#define MINIMUM_RADIUS 30.0
#define MAXIMUM_RADIUS 70.0
#define BUTTON_RADIUS 25.0

#define KONOTOR_BOTTOM_EXTRAPADDING 12


@interface KonotorVoiceInputOverlay : NSObject

@property (strong, nonatomic) UIView* transparentView;
@property (strong, nonatomic) UIView* containerWidget;
@property (strong, nonatomic) UIView* voiceFeedbackAnimatorView1;
@property (strong, nonatomic) UIView* voiceFeedbackAnimatorView2;
@property (strong, nonatomic) UILabel* timerLabel;
@property (strong, nonatomic) UIView* window;
@property (strong, nonatomic) UIButton* cancelButton;
@property (strong, nonatomic) UIButton* sendButton;
@property (strong, nonatomic) UIButton* stopButton;
@property (strong, nonatomic) UIButton* playButton;
@property (strong, nonatomic) NSTimer* feedbackAnimationTimer;
@property (nonatomic) BOOL isLinearInput;


+(KonotorVoiceInputOverlay*) sharedInstance;

+(BOOL) showInputLinearForView:(UIView*) view;
+(void) rotateToOrientation:(UIInterfaceOrientation) orientation duration:(NSTimeInterval) duration;
+(void) dismissVoiceInputOverlay;
+(void) dismissVoiceInput;



@end
