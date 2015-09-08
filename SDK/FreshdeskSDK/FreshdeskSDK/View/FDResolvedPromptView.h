//
//  FDResolvedPromptView.h
//  FreshdeskSDK
//
//  Created by Arvchz on 23/02/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FDPromptView.h"

@protocol FDResolvedPromptViewDelegate <NSObject>

-(void)handleTicketResolved;
-(void)handleTicketNotResolved;

@end

@interface FDResolvedPromptView : FDPromptView

-(instancetype)initWithDelegate:(id <FDResolvedPromptViewDelegate>)delegate;

@end