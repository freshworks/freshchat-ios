//
//  FDInputToolbarView.h
//  FreshdeskSDK
//
//  Created by Arvchz on 15/05/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FDInputToolbarViewDelegate <NSObject>

-(void)inputToolbarAttachmentButtonPressed:(id)sender;
-(void)inputToolbarSendButtonPressed:(id)sender;

@end

@interface FDInputToolbarView : UIView

@property (strong, nonatomic) UITextView *inputTextView;

-(instancetype) initWithDelegate:(id <FDInputToolbarViewDelegate, UITextViewDelegate>)delegate;
-(void)enableSendButton:(BOOL)state;
-(void)showAttachButton:(BOOL)state;

@end