//
//  FDTicketStateDisplayer.h
//  FreshdeskSDK
//
//  Created by AravinthChandran on 27/01/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FDPromptView.h"

@protocol FDTicketStateHandlerDelegate <NSObject>

-(void)ticketStateOnResolved;
-(void)ticketStateOnNotResolved;
-(void)ticketStateOnInitiateNewConversation;

-(void)displayPromptView:(FDPromptView *)promptView;
-(void)clearPromptView:(FDPromptView *)promptView;

@end

@interface FDTicketStateHandler : NSObject

@property (nonatomic) BOOL ignorePrompts;

-(instancetype)initWithDelegate:(id <FDTicketStateHandlerDelegate>)delegate;
-(void)handleTicketState:(NSInteger)newState;

@end