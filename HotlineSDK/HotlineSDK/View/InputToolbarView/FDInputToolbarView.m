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
#import "TargetConditionals.h"
#import "HLLocalization.h"
#import "FDSecureStore.h"
#import "FDAutolayoutHelper.h"

@interface FDInputToolbarView () <UITextViewDelegate>{
    
    NSString *placeHolderText;
}
@property (strong, nonatomic) UIView               *accessoryViewContainer;
@property (strong, nonatomic) UIImageView          *innerImageView;
@property (strong, nonatomic) UIImageView          *outerImageView;
@property (nonatomic, strong) NSLayoutConstraint   *attachButtonWidthConstraint;
@property (nonatomic, strong) HLTheme              *theme;
@property (nonatomic, strong) NSLayoutConstraint   *attachButtonYConstraint;
@property (weak, nonatomic) id <FDInputToolbarViewDelegate> delegate;
@property (nonatomic) BOOL canShowAttachButton;

@property (nonatomic, strong) NSLayoutConstraint   *accessoryViewWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint   *accessoryViewHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint   *accessoryViewYConstraint;

@property (nonatomic, assign) BOOL isVoiceMessageEnabled;

@end

@implementation FDInputToolbarView

@synthesize innerImageView, outerImageView,textView, sendButton, attachButton, attachButtonWidthConstraint,
micButton, attachButtonYConstraint, accessoryViewYConstraint, accessoryViewContainer, accessoryViewHeightConstraint, accessoryViewWidthConstraint;

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
        micButton.backgroundColor = [UIColor clearColor];
        micButton.translatesAutoresizingMaskIntoConstraints = NO;
        UIImage *micImage = [[HLTheme sharedInstance]getImageWithKey:IMAGE_INPUT_TOOLBAR_MIC];
        [micButton setImage:micImage forState:UIControlStateNormal];
        micButton.backgroundColor = [UIColor clearColor];
        [micButton addTarget:self action:@selector(micButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        sendButton = [FDButton buttonWithType:UIButtonTypeSystem];
        sendButton.backgroundColor = [UIColor clearColor];
        [sendButton setTitle:HLLocalizedString(LOC_SEND_BUTTON_TEXT) forState:UIControlStateNormal];
        [sendButton setTitleColor:[self.theme sendButtonColor] forState:UIControlStateNormal];
        sendButton.translatesAutoresizingMaskIntoConstraints = NO;
        [sendButton addTarget:self action:@selector(sendButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        accessoryViewContainer = [UIView new];
        accessoryViewContainer.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addSubview:textView];
        [self addSubview:accessoryViewContainer];
        [self addSubview:attachButton];
        
        [accessoryViewContainer addSubview:micButton];
        [accessoryViewContainer addSubview:sendButton];
        
        NSMutableDictionary *views = [NSMutableDictionary dictionaryWithDictionary:NSDictionaryOfVariableBindings(attachButton,textView,
                                                                                                                  sendButton, micButton, accessoryViewContainer)];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[textView]-5-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[attachButton]-5-[textView]-5-[accessoryViewContainer]-5-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[attachButton(24)]" options:0 metrics:nil views:views]];

        [accessoryViewContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[micButton(20)]" options:0 metrics:nil views:views]];
        [accessoryViewContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[micButton(24)]" options:0 metrics:nil views:views]];
        
        [FDAutolayoutHelper center:sendButton onView:accessoryViewContainer];
        [FDAutolayoutHelper center:micButton onView:accessoryViewContainer];
        
        [self addVariableConstraints];
        
    }
    return self;
}

-(void)addVariableConstraints{
    attachButtonYConstraint       = [FDAutolayoutHelper bottomAlign:attachButton toView:self];
    attachButtonWidthConstraint   = [FDAutolayoutHelper setWidth:0 forView:attachButton inView:self];
    accessoryViewYConstraint      = [FDAutolayoutHelper bottomAlign:accessoryViewContainer toView:self];
    accessoryViewWidthConstraint  = [FDAutolayoutHelper setWidth:0 forView:accessoryViewContainer inView:self];
    accessoryViewHeightConstraint = [FDAutolayoutHelper setHeight:20 forView:accessoryViewContainer inView:self];
}


-(void)prepareView{
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    BOOL isPictureMessageEnabled = [[FDSecureStore sharedInstance] boolValueForKey:HOTLINE_DEFAULTS_PICTURE_MESSAGE_ENABLED];
    attachButtonWidthConstraint.constant = (isPictureMessageEnabled) ? 24.0 : 0;
    self.isVoiceMessageEnabled = [[FDSecureStore sharedInstance] boolValueForKey:HOTLINE_DEFAULTS_VOICE_MESSAGE_ENABLED];

    [self updateActionButtons:textView];
    
    //Vertically center buttons in the toolbar
    CGFloat attachButtonYpos = (self.frame.size.height - self.attachButton.frame.size.height)/2.0;
    attachButtonYConstraint.constant = - attachButtonYpos;
    
    CGFloat accessoryViewYpos = (self.frame.size.height - self.accessoryViewContainer.frame.size.height)/2.0;
    accessoryViewYConstraint.constant = - accessoryViewYpos;
}

-(void)showAttachButton:(BOOL)state{
    self.canShowAttachButton = state;
}

#pragma mark Button Actions

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

#pragma mark Text view delegates

- (void)textViewDidChange:(UITextView *)inputTextView{
    [self updateActionButtons:inputTextView];
    [self.delegate inputToolbar:self textViewDidChange:inputTextView];
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

-(void)updateActionButtons:(UITextView *)inputTextView{
    if(!self.isVoiceMessageEnabled){
        [self showMicButton:NO];
    }else{
        BOOL isTextViewEmpty = ([inputTextView.text isEqualToString:@""] || [inputTextView.text isEqualToString:placeHolderText]);
        [self showMicButton:isTextViewEmpty];
    }
}

-(void)showMicButton:(BOOL)canShow{
    if (canShow) {
        self.micButton.hidden = NO;
        self.sendButton.hidden = YES;
        accessoryViewWidthConstraint.constant = self.micButton.frame.size.width;
    }else{
        self.micButton.hidden = YES;
        self.sendButton.hidden = NO;
        accessoryViewWidthConstraint.constant = self.sendButton.frame.size.width;
    }
}

@end