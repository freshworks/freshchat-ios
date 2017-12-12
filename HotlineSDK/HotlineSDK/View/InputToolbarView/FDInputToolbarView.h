//
//  FDInputToolbarView.h
//  FreshdeskSDK
//
//  Created by Arvchz on 15/05/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDButton.h"

@class FDInputToolbarView;

@protocol FDInputToolbarViewDelegate <NSObject>

-(void)inputToolbar:(FDInputToolbarView *)toolbar attachmentButtonPressed:(id)sender;
-(void)inputToolbar:(FDInputToolbarView *)toolbar sendButtonPressed:(id)sender;
-(void)inputToolbar:(FDInputToolbarView *)toolbar micButtonPressed:(id)sender;
-(void)inputToolbar:(FDInputToolbarView *)toolbar textViewDidChange:(UITextView *)textView;

@end

@interface FDInputToolbarView : UIView<UITextViewDelegate>
@property (nonatomic) CGFloat  textViewHt;
@property (strong, nonatomic) FDButton *micButton;
@property (strong, nonatomic) FDButton *sendButton;
@property (strong, nonatomic) FDButton *attachButton;
@property (strong, nonatomic) UITextView *textView;
@property (nonatomic, strong) UIView *dividerView;
@property (nonatomic) BOOL isFromAttachmentScreen;
@property (weak, nonatomic) id <FDInputToolbarViewDelegate> delegate;

-(instancetype) initWithDelegate:(id <FDInputToolbarViewDelegate>)delegate;
-(void)showAttachButton:(BOOL)state;
-(void)prepareView;
-(BOOL)containsUserInputText;

@end
