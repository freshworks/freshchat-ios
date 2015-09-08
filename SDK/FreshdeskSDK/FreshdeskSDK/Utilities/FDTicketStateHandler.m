//
//  FDTicketStateDisplayer.m
//  FreshdeskSDK
//
//  Created by AravinthChandran on 27/01/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FDAPI.h"
#import "FDMacros.h"
#import "FDConstants.h"
#import "FDTicketStateHandler.h"
#import "FDNewTicketViewController.h"
#import "FDNoteListViewController.h"
#import "FDBorderedButton.h"
#import "FDClosedPromptView.h"
#import "FDResolvedPromptView.h"

@interface FDTicketStateHandler () <FDResolvedPromptViewDelegate, FDClosedPromptViewDelegate>

@property (strong, nonatomic) FDPromptView *currentPromptView;
@property (nonatomic        ) NSInteger lastUpdatedTicketState;
@property (nonatomic, weak  ) id<FDTicketStateHandlerDelegate> delegate;

@end

@implementation FDTicketStateHandler

-(instancetype)initWithDelegate:(id <FDTicketStateHandlerDelegate>)delegate{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.ignorePrompts = NO;
    }
    return self;
}

-(void)handleTicketState:(NSInteger)newState{
    if (self.lastUpdatedTicketState == newState) {
        FDLog(@"Ticket handler hitting the same state, don't take any action");
        return;
    }
    
    if(self.ignorePrompts) {
        return;
    }

    [self clearPrompt];
    
    switch (newState) {
            
        case MOBIHELP_TICKET_STATUS_CLOSED:
            [self displayClosedTicketPrompt];
            break;
            
        case MOBIHELP_TICKET_STATUS_RESOLVED:
            [self displayResolvedTicketPrompt];
            break;
            
        default:
            break;
    }
    
    self.lastUpdatedTicketState = newState;
}

-(void)clearPrompt{
    if (self.currentPromptView) {
        [self.delegate clearPromptView:self.currentPromptView];
    }
}

-(void)displayClosedTicketPrompt{
    FDClosedPromptView *closedPromptView = [[FDClosedPromptView alloc]initWithDelegate:self];
    closedPromptView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.delegate displayPromptView:closedPromptView];
    self.currentPromptView = closedPromptView;
}

-(void)displayResolvedTicketPrompt{
    FDResolvedPromptView *resolvedPromptView = [[FDResolvedPromptView alloc]initWithDelegate:self];
    resolvedPromptView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.delegate displayPromptView:resolvedPromptView];
    self.currentPromptView = resolvedPromptView;
}

-(void)handleTicketResolved{
    [self.delegate ticketStateOnResolved];
}

-(void)handleTicketNotResolved{
    [self.delegate ticketStateOnNotResolved];
}

-(void)closedPromptOnStartingNewConversation{
    [self.delegate ticketStateOnInitiateNewConversation];
}

@end