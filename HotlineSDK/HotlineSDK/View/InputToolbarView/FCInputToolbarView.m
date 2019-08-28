//
//  FDInputToolbarView.m
//  FreshdeskSDK
//
//  Created by Arvchz on 15/05/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FCInputToolbarView.h"
#import "FCTheme.h"
#import "FCMacros.h"
#import "FreshchatSDK.h"
#import <AudioToolbox/AudioServices.h>
#import "TargetConditionals.h"
#import "FCLocalization.h"
#import "FCSecureStore.h"
#import "FCAutolayoutHelper.h"
#import "FCPlistManager.h"
#import "FCStringUtil.h"

#define FC_SEND_BTN_VERTICAL_PADDING 8
#define FC_SEND_BTN_HOTIZONTAL_PADDING 8

@interface FCInputToolbarView () <UITextViewDelegate>{
    NSString *placeHolderText;
}
@property (strong, nonatomic) UIView   *accessoryViewContainer;
@property (strong, nonatomic) UIImageView          *innerImageView;
@property (strong, nonatomic) UIImageView          *outerImageView;
@property (nonatomic, strong) NSLayoutConstraint   *attachButtonWidthConstraint;
@property (nonatomic, strong) FCTheme              *theme;
@property (nonatomic, strong) NSLayoutConstraint   *attachButtonYConstraint;
@property (nonatomic) BOOL canShowAttachButton;

@property (nonatomic, strong) NSLayoutConstraint   *accessoryViewWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint   *accessoryViewHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint   *accessoryViewYConstraint;
@property (nonatomic, strong) UILabel *placeholderLabel;

@property (nonatomic, assign) BOOL isVoiceMessageEnabled;

@end

@implementation FCInputToolbarView

@synthesize innerImageView, outerImageView,textView, sendButton, attachButton, attachButtonWidthConstraint,
micButton, attachButtonYConstraint, accessoryViewYConstraint, accessoryViewContainer, accessoryViewHeightConstraint, accessoryViewWidthConstraint, dividerView, placeholderLabel;

-(instancetype)initWithDelegate:(id <FDInputToolbarViewDelegate>)delegate{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.theme = [FCTheme sharedInstance];
        self.isFromAttachmentScreen = NO;
        self.backgroundColor = [self.theme inputToolbarBackgroundColor];
        dividerView = [[UIView alloc] init];
        dividerView.translatesAutoresizingMaskIntoConstraints = NO;
        dividerView.backgroundColor = [[FCTheme sharedInstance] inputToolbarDividerColor];
        
        textView=[[UITextView alloc] init];
        [textView setFont:[self.theme inputTextFont]];
        [textView setTextColor:[self.theme inputTextFontColor]];
        textView.tintColor = [self.theme inputTextCursorColor];
        textView.layer.borderColor=[[self.theme inputTextBorderColor] CGColor];
        textView.textAlignment = NSTextAlignmentNatural;
        textView.layer.cornerRadius=5.0;
        textView.layer.borderWidth=1.0;
        textView.delegate = self;
        textView.backgroundColor = [self.theme inputTextfieldBackgroundColor];
        [textView setTranslatesAutoresizingMaskIntoConstraints:NO];
        textView.delegate = self;
        
        placeholderLabel = [[UILabel alloc] init];
        placeholderLabel.text = HLLocalizedString(LOC_MESSAGE_PLACEHOLDER_TEXT);
        [placeholderLabel setTextColor:[self.theme inputTextPlaceholderFontColor]];
        [placeholderLabel setFont:[self.theme inputTextFont]];
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        attachButton = [FCButton buttonWithType:UIButtonTypeCustom];
        attachButton.translatesAutoresizingMaskIntoConstraints = NO;
        attachButton.backgroundColor = [UIColor clearColor];
        UIImage *attachmentImage = [self.theme getImageValueWithKey:IMAGE_ATTACH_ICON];
        [attachButton setImage:attachmentImage forState:UIControlStateNormal];
        [attachButton addTarget:self action:@selector(attachmentButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        micButton = [FCButton buttonWithType:UIButtonTypeCustom];
        micButton.backgroundColor = [UIColor clearColor];
        micButton.translatesAutoresizingMaskIntoConstraints = NO;
        UIImage *micImage = [[FCTheme sharedInstance]getImageValueWithKey:IMAGE_INPUT_TOOLBAR_MIC];
        [micButton setImage:micImage forState:UIControlStateNormal];
        micButton.backgroundColor = [UIColor clearColor];
        [micButton addTarget:self action:@selector(micButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        
        sendButton = [FCButton buttonWithType:UIButtonTypeSystem];
        sendButton.backgroundColor = [UIColor clearColor];
        //Only inc. surface area, No interfere with current button size
        sendButton.imageEdgeInsets = UIEdgeInsetsMake(-FC_SEND_BTN_VERTICAL_PADDING, -FC_SEND_BTN_HOTIZONTAL_PADDING, -FC_SEND_BTN_VERTICAL_PADDING, -FC_SEND_BTN_HOTIZONTAL_PADDING);
        UIImage *sendImage = [self.theme getImageValueWithKey:IMAGE_SEND_ICON];
        if(sendImage != nil){
            [sendButton setBackgroundImage:sendImage forState:UIControlStateNormal];
        }
        else{
            [sendButton setTitle:HLLocalizedString(LOC_SEND_BUTTON_TEXT) forState:UIControlStateNormal];
            [sendButton setTitleColor:[self.theme sendButtonColor] forState:UIControlStateNormal];
        }
        sendButton.translatesAutoresizingMaskIntoConstraints = NO;
        [sendButton addTarget:self action:@selector(sendButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        accessoryViewContainer = [UIView new];
        accessoryViewContainer.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:dividerView];
        [self addSubview:textView];
        [self addSubview:accessoryViewContainer];
        [self addSubview:attachButton];
        [self addSubview:placeholderLabel];
        
        [accessoryViewContainer addSubview:micButton];
        [accessoryViewContainer addSubview:sendButton];
        
        NSMutableDictionary *views = [NSMutableDictionary dictionaryWithDictionary:NSDictionaryOfVariableBindings(dividerView, attachButton, textView, sendButton, micButton, accessoryViewContainer, placeholderLabel)];
        
        NSDictionary *metrics = @{
                                  @"kPadding" : @5,
                                  @"kPaddingWithTxtV" : @10
                                  };//used to avoid multple values, for single values its not req.
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[dividerView]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[dividerView(1)]-4-[textView]-kPadding-|" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-kPadding-[attachButton]-kPadding-[textView]-kPadding-[accessoryViewContainer]-kPadding-|" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[attachButton(24)]" options:0 metrics:nil views:views]];

        [accessoryViewContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[micButton(20)]" options:0 metrics:nil views:views]];
        [accessoryViewContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[micButton(24)]" options:0 metrics:nil views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[dividerView]-4-[placeholderLabel]-kPadding-|" options:0 metrics:metrics views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[attachButton]-kPaddingWithTxtV-[placeholderLabel]-kPadding-[accessoryViewContainer]" options:0 metrics:metrics views:views]];//kPaddingWithTxtV include kPadding + 5 as default textView padding
        
        [FCAutolayoutHelper center:sendButton onView:accessoryViewContainer];
        [FCAutolayoutHelper center:micButton onView:accessoryViewContainer];
        
        [self addVariableConstraints];
        
    }
    return self;
}

-(void)addVariableConstraints{
    attachButtonYConstraint       = [FCAutolayoutHelper bottomAlign:attachButton toView:self];
    attachButtonWidthConstraint   = [FCAutolayoutHelper setWidth:0 forView:attachButton inView:self];
    accessoryViewYConstraint      = [FCAutolayoutHelper bottomAlign:accessoryViewContainer toView:self];
    accessoryViewWidthConstraint  = [FCAutolayoutHelper setWidth:0 forView:accessoryViewContainer inView:self];
    accessoryViewHeightConstraint = [FCAutolayoutHelper setHeight:20 forView:accessoryViewContainer inView:self];
}

-(void)prepareView{
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    FCPlistManager *plistManager = [FCPlistManager new];

    BOOL isPictureMessageEnabled = ([plistManager isGallerySelectionEnabled] || [plistManager isCameraCaptureEnabled]) ? YES : NO;

    attachButtonWidthConstraint.constant = (!self.isFromAttachmentScreen && isPictureMessageEnabled) ? 24.0 : 0;
    
    self.isVoiceMessageEnabled = [plistManager isVoiceMessageEnabled] && !self.isFromAttachmentScreen;

    [self updateAudioRecBtn:textView];
    
    //Vertically center buttons in the toolbar
    CGFloat attachButtonYpos = (self.frame.size.height - self.attachButton.frame.size.height)/2.0;
    attachButtonYConstraint.constant = - attachButtonYpos;
    
    CGFloat ht = self.isFromAttachmentScreen ? self.textViewHt + 10 : self.frame.size.height;
    CGFloat accessoryViewYpos = ( ht - self.accessoryViewContainer.frame.size.height)/2.0;
    accessoryViewYConstraint.constant = - accessoryViewYpos;
}

#pragma mark Button Actions

-(void)showAttachButton:(BOOL)state{
    self.canShowAttachButton = state;
}

-(void)attachmentButtonAction:(id)sender{
    [self.delegate inputToolbar:self attachmentButtonPressed:sender];
}

-(void)sendButtonAction:(id)sender{
    [self.delegate inputToolbar:self sendButtonPressed:sender];
    [self updateAudioRecBtn:self.textView];
    self.placeholderLabel.hidden = NO;
}

-(void)micButtonAction:(id)sender{
    if (!TARGET_IPHONE_SIMULATOR) {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    }
    [self.delegate inputToolbar:self micButtonPressed:sender];
}

#pragma mark Send Button State

- (void) setSendButtonEnabled : (BOOL) state{
    sendButton.enabled = state;
    sendButton.alpha = state ? 1.0 : 0.6;
}

#pragma mark Text view delegates

- (void)textViewDidChange:(UITextView *)inputTextView{
    [self updateAudioRecBtn:inputTextView];
    self.placeholderLabel.hidden =  [FCStringUtil isNotEmptyString: inputTextView.text];
    [self.delegate inputToolbar:self textViewDidChange:inputTextView];
    if(!self.isFromAttachmentScreen){
        [self setSendButtonEnabled:[FCStringUtil isNotEmptyString: inputTextView.text]];
    }
}

- (void)textViewDidBeginEditing:(UITextView *)chatTextView{
    [chatTextView becomeFirstResponder];
}

//TODO: Replace once support for audio is enabled
-(void)updateAudioRecBtn:(UITextView *)inputTextView{
//    if(true) {
//        [self showMicButton:NO];
//    }else{
//        BOOL isTextViewEmpty = ([inputTextView.text isEqualToString:@""] || [inputTextView.text isEqualToString:placeHolderText]); //Pass this as parameter in showmicbutton
        [self showMicButton:NO] ;
//    }
}

-(void)showMicButton:(BOOL)canShow{
    if (canShow) {
        self.micButton.hidden = NO;
        self.sendButton.hidden = YES;
        accessoryViewWidthConstraint.constant = self.micButton.frame.size.width;
    }else {
        self.micButton.hidden = YES;
        self.sendButton.hidden = NO;
        accessoryViewWidthConstraint.constant = self.sendButton.frame.size.width;
    }
}

@end
