//
//  FDCSATYesNoPrompt.m
//  HotlineSDK
//
//  Created by user on 29/11/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FDCSATYesNoPrompt.h"
#import "HLMacros.h"
#import "HLLocalization.h"

@implementation FDCSATYesNoPrompt

-(instancetype)initWithDelegate:(id<FDYesNoPromptViewDelegate>) delegate andKey:(NSString *)key{
    self = [super init];
    if (self) {
        self.theme = [HLTheme sharedInstance];
        
        self.promptLabel = [self createPromptLabel:key];
        [self addSubview:self.promptLabel];
        
        self.YesButton = [self createBorderedPromptButton:@"yes" withKey:key];
        [self.YesButton setTitleColor:[self.theme custSatDialogueYesButtonTextColor] forState:UIControlStateNormal];
        [self.YesButton setBackgroundColor:[self.theme custSatDialogueYesButtonBackgroundColor]];
        [self.YesButton.titleLabel setFont:[self.theme custSatDialogueYesButtonFont]];
        self.YesButton.layer.borderColor = [[self.theme custSatDialogueYesButtonBorderColor] CGColor];
        
        [self.YesButton addTarget:self.delegate action:@selector(yesButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.YesButton];
        
        self.NoButton = [self createBorderedPromptButton:@"no" withKey:key];
        [self.NoButton setTitleColor:[self.theme custSatDialogueNoButtonTextColor] forState:UIControlStateNormal];
        [self.NoButton setBackgroundColor:[self.theme custSatDialogueNoButtonBackgroundColor]];
        [self.NoButton.titleLabel setFont:[self.theme custSatDialogueNoButtonFont]];
        self.NoButton.layer.borderColor = [[self.theme custSatDialogueNoButtonBorderColor] CGColor];
        
        [self.NoButton addTarget:self.delegate action:@selector(noButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.NoButton];
        
        [self addSpacersInView:self];
    }
    return self;
}

@end
