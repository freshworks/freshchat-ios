//
//  KonotorMediaUIButton.h
//  KonotorDemo
//
//  Created by Srikrishnan Ganesan on 11/08/13.
//  Copyright (c) 2013 Demach. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Konotor.h"

enum KonotorMediaUIButtonState {
    KonotorMediaUIButtonStatePlaying = 1,
    KonotorMediaUIButtonStateStopped = 2
};

@interface KonotorMediaUIButton : UIButton

@property (strong, nonatomic) NSString* messageID;
@property (strong, nonatomic) UISlider* mediaProgressBar;
@property (strong, nonatomic) NSTimer* progressAnimationTimer;
@property (strong, nonatomic) KonotorMessageData* message;
@property (nonatomic) enum KonotorMediaUIButtonState buttonState;

- (void) startAnimating;
- (void) stopAnimating;

@end
