//
//  FDInputToolbarView.m
//  FreshdeskSDK
//
//  Created by Arvchz on 15/05/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FDInputToolbarView.h"
#import "HLTheme.h"
#import "HLMacros.h"
#import "Hotline.h"
#import <AudioToolbox/AudioServices.h>
#include "TargetConditionals.h"
#include "HLLocalization.h"
#import "FDSecureStore.h"

@interface FDInputToolbarView () <UITextViewDelegate>{
    
    NSString *placeHolderText;
}

@property (strong, nonatomic) UIImageView          *innerImageView;
@property (strong, nonatomic) UIImageView          *outerImageView;
@property (nonatomic, strong) NSLayoutConstraint   *attachButtonWidthConstraint;
@property (nonatomic, strong) HLTheme              *theme;
@property (weak, nonatomic) id <FDInputToolbarViewDelegate> delegate;
@property (nonatomic) BOOL canShowAttachButton;
@property (nonatomic, assign) BOOL isVoiceMessageEnabled;

@end

@implementation FDInputToolbarView

@synthesize innerImageView, outerImageView,textView, sendButton, attachButton, attachButtonWidthConstraint, micButton;

-(instancetype)initWithDelegate:(id <FDInputToolbarViewDelegate>)delegate{
    self = [super init];
    if (self) {
        
        self.delegate = delegate;
        self.theme = [HLTheme sharedInstance];
        
        self.backgroundColor=[UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
   
        textView=[[UITextView alloc] init];
        [textView setFont:[self.theme inputTextFont]];
        [textView setTextColor:[UIColor lightGrayColor]];
        textView.layer.borderColor=[[UIColor lightGrayColor] CGColor];
        textView.layer.cornerRadius=5.0;
        textView.layer.borderWidth=1.0;
        textView.delegate = self;
        [textView setTranslatesAutoresizingMaskIntoConstraints:NO];
        placeHolderText = HLLocalizedString(LOC_MESSAGE_PLACEHOLDER_TEXT);
        textView.text = placeHolderText;
        textView.delegate = self;

        attachButton = [FDButton buttonWithType:UIButtonTypeCustom];
        attachButton.translatesAutoresizingMaskIntoConstraints = NO;
        UIImage *attachmentImage = [self.theme getImageWithKey:IMAGE_ATTACH_ICON];
        [attachButton setImage:attachmentImage forState:UIControlStateNormal];
        attachButton.backgroundColor = [UIColor clearColor];
        [attachButton addTarget:self action:@selector(attachmentButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        micButton = [FDButton buttonWithType:UIButtonTypeCustom];
        micButton.translatesAutoresizingMaskIntoConstraints = NO;
        UIImage *micImage = [[HLTheme sharedInstance]getImageWithKey:IMAGE_INPUT_TOOLBAR_MIC];
        [micButton setImage:micImage forState:UIControlStateNormal];
        micButton.backgroundColor = [UIColor clearColor];
        [micButton addTarget:self action:@selector(micButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        sendButton = [FDButton buttonWithType:UIButtonTypeSystem];
        [sendButton setTitle:HLLocalizedString(LOC_SEND_BUTTON_TEXT) forState:UIControlStateNormal];
        [sendButton setTitleColor:[self.theme sendButtonColor] forState:UIControlStateNormal];
        sendButton.translatesAutoresizingMaskIntoConstraints = NO;
        [sendButton addTarget:self action:@selector(sendButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:textView];
        [self addSubview:attachButton];
        [self addSubview:micButton];
        [self addSubview:sendButton];
    }
    return self;
}

- (void)textViewDidBeginEditing:(UITextView *)chatTextView{
    if ([chatTextView.text isEqualToString:placeHolderText]){
        chatTextView.text = @"";
    }
    [chatTextView setTextColor:[self.theme inputTextFontColor]];
    chatTextView.textColor = [[HLTheme sharedInstance] inputTextFontColor];
    [chatTextView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)chatTextView{
    NSString *currentText = trimString(chatTextView.text);
    if ([currentText isEqualToString:@""]) {
        chatTextView.text = placeHolderText;
        chatTextView.textColor = [UIColor lightGrayColor]; //optional
    }
}

-(void)attachmentButtonAction:(id)sender{
    [self.delegate inputToolbar:self attachmentButtonPressed:sender];
}

-(void)sendButtonAction:(id)sender{
    [self.delegate inputToolbar:self sendButtonPressed:sender];
    [self updateActionButtons:self.textView];
}

-(void)micButtonAction:(id)sender{
    if (!TARGET_IPHONE_SIMULATOR) {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    }
    [self.delegate inputToolbar:self micButtonPressed:sender];
}

-(void)layoutSubviews{
    NSMutableDictionary *views = [NSMutableDictionary dictionaryWithDictionary:NSDictionaryOfVariableBindings(attachButton,textView, sendButton, micButton)];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[textView]-5-|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[sendButton(20)]-10-|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[attachButton(24)]" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[attachButton(24)]-[textView]-[sendButton(40)]-5-|" options:0 metrics:nil views:views]];
    
    //Mic button constraints
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[micButton(24)]" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[textView]-[micButton(40)]-5-|" options:0 metrics:nil views:views]];

    attachButtonWidthConstraint = [NSLayoutConstraint constraintWithItem:attachButton
                                                               attribute:NSLayoutAttributeWidth
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:nil
                                                               attribute:NSLayoutAttributeNotAnAttribute
                                                              multiplier:1.0
                                                                constant:0.0];
    
    FDSecureStore *store = [FDSecureStore sharedInstance];
    BOOL isPictureMessageEnabled = [store boolValueForKey:HOTLINE_DEFAULTS_PICTURE_MESSAGE_ENABLED];
    self.isVoiceMessageEnabled = [store boolValueForKey:HOTLINE_DEFAULTS_VOICE_MESSAGE_ENABLED];
    
    
    if(!isPictureMessageEnabled){
        attachButtonWidthConstraint.constant = 0;
    }
    else{
        attachButtonWidthConstraint.constant = 24.0;
    }
    
    [self addConstraint:attachButtonWidthConstraint];
    
    if(!self.isVoiceMessageEnabled){
        [self disableAudioMessaging];
    }
    else{
        [self updateActionButtons:textView];
    }
    [super layoutSubviews];
}

- (void) disableAudioMessaging{
    
    self.micButton.hidden = YES;
    self.sendButton.hidden = NO;
}

-(void)updateActionButtons:(UITextView *)inputTextView{
    BOOL isTextViewEmpty = ([inputTextView.text isEqualToString:@""] || [inputTextView.text isEqualToString:placeHolderText]);
    if(!self.isVoiceMessageEnabled){
        [self disableAudioMessaging];
    }
    else{
        self.sendButton.hidden = isTextViewEmpty;
        self.micButton.hidden = !isTextViewEmpty;
    }
}

-(void)showAttachButton:(BOOL)state{
    self.canShowAttachButton = state;
}

- (void) textViewDidChange:(UITextView *)inputTextView{
    [self updateActionButtons:inputTextView];
    [self.delegate inputToolbar:self textViewDidChange:inputTextView];
}

@end