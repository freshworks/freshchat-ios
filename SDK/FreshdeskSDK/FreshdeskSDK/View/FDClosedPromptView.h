//
//  FDClosedPromptView.h
//  FreshdeskSDK
//
//  Created by Arvchz on 23/02/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FDPromptView.h"

@protocol FDClosedPromptViewDelegate <NSObject>

-(void)closedPromptOnStartingNewConversation;

@end

@interface FDClosedPromptView : FDPromptView

-(instancetype)initWithDelegate:(id <FDClosedPromptViewDelegate>)delegate;

@end
