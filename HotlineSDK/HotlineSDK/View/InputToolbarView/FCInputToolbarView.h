//
//  FDInputToolbarView.h
//  FreshdeskSDK
//
//  Created by Arvchz on 15/05/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FCButton.h"

@class FCInputToolbarView;

@protocol FDInputToolbarViewDelegate <NSObject>

-(void)inputToolbar:(FCInputToolbarView *)toolbar attachmentButtonPressed:(id)sender;
-(void)inputToolbar:(FCInputToolbarView *)toolbar sendButtonPressed:(id)sender;
-(void)inputToolbar:(FCInputToolbarView *)toolbar micButtonPressed:(id)sender;
-(void)inputToolbar:(FCInputToolbarView *)toolbar textViewDidChange:(UITextView *)textView;

@end

@interface FCInputToolbarView : UIView<UITextViewDelegate>
@property (nonatomic) CGFloat  textViewHt;
@property (strong, nonatomic) FCButton *micButton;
@property (strong, nonatomic) FCButton *sendButton;
@property (strong, nonatomic) FCButton *attachButton;
@property (strong, nonatomic) UITextView *textView;
@property (nonatomic, strong) UIView *dividerView;
@property (nonatomic) BOOL isFromAttachmentScreen;
@property (weak, nonatomic) id <FDInputToolbarViewDelegate> delegate;

-(instancetype) initWithDelegate:(id <FDInputToolbarViewDelegate>)delegate;
-(void)showAttachButton:(BOOL)state;
-(void)prepareView;
-(void)setSendButtonEnabled : (BOOL) state;

@end
