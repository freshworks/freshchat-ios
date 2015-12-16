//
//  FDAudioMessageUnit.h
//  HotlineSDK
//
//  Created by Srikrishnan Ganesan on 27/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FDMessageCell.h"
#import "Konotor.h"

enum FDAudioMessageMediaState {
    FDAudioMessageMediaStatePlaying = 1,
    FDAudioMessageMediaStateStopped = 2
};

@class FDMessage;

#define KONOTOR_AUDIOMESSAGE_HEIGHT 44
#define KONOTOR_PLAYBUTTON_DIMENSION 40


@interface FDAudioMessageUnit : NSObject

@property (strong, nonatomic) UIButton* audioPlayButton;
@property (strong, nonatomic) NSString* messageID;
@property (strong, nonatomic) UISlider* mediaProgressBar;
@property (strong, nonatomic) NSTimer* progressAnimationTimer;
@property (strong, nonatomic) FDMessage* message;
@property (nonatomic) enum FDAudioMessageMediaState playbackState;

- (void) startAnimating;
- (void) stopAnimating;
- (void) setHidden:(BOOL)hidden;
- (void) setUpView;
- (void) displayMessage:(FDMessage*) message;

@end
