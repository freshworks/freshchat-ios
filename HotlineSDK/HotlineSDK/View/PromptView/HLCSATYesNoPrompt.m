//
//  HLCSATYesNoPrompt.m
//  HotlineSDK
//
//  Created by user on 29/11/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "HLCSATYesNoPrompt.h"
#import "HLMacros.h"
#import "HLLocalization.h"

@implementation HLCSATYesNoPrompt

-(instancetype)initWithDelegate:(id<HLYesNoPromptViewDelegate>) delegate andKey:(NSString *)key{
    self = [super init];
    if (self) {
        self.theme = [HLTheme sharedInstance];
        
        self.promptLabel = [self createCSATPromptLabel:key];
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

-(UILabel *)createCSATPromptLabel:(NSString *) key{
    UILabel *promptLabel = [[UILabel alloc] init];
    HLTheme *theme = [HLTheme sharedInstance];
    self.backgroundColor = [theme custSatDialogueBackgroundColor];
    promptLabel.translatesAutoresizingMaskIntoConstraints = NO;
    promptLabel.textColor = [theme custSatDialogueTitleTextColor];
    promptLabel.font = [theme custSatDialogueTitleFont];
    promptLabel.lineBreakMode = NSLineBreakByWordWrapping;
    promptLabel.numberOfLines = 0;
    promptLabel.textAlignment= NSTextAlignmentCenter;
    promptLabel.text = HLLocalizedString([key stringByAppendingString:
                                          LOC_TEXT_PARTIAL]);
    return promptLabel;
}

@end
