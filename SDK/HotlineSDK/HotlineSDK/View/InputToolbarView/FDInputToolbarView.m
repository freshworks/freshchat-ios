//
//  FDInputToolbarView.m
//  FreshdeskSDK
//
//  Created by Arvchz on 15/05/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FDInputToolbarView.h"
#import "FDButton.h"
#import "HLTheme.h"
#import "HLMacros.h"

@interface FDInputToolbarView ()

@property (strong, nonatomic) FDButton             *sendButton;
@property (strong, nonatomic) FDButton             *attachButton;
@property (strong, nonatomic) UIImageView          *innerImageView;
@property (strong, nonatomic) UIImageView          *outerImageView;
@property (nonatomic, strong) NSLayoutConstraint   *attachButtonWidthConstraint;
@property (nonatomic, strong) HLTheme              *theme;
@property (weak, nonatomic) id <FDInputToolbarViewDelegate> delegate;
@property (nonatomic) BOOL canShowAttachButton;

@end

@implementation FDInputToolbarView

@synthesize textView, innerImageView, outerImageView, sendButton, attachButton, attachButtonWidthConstraint;

-(instancetype)initWithDelegate:(id <FDInputToolbarViewDelegate, FDGrowingTextViewDelegate>)delegate{
    self = [super init];
    if (self) {
        
        self.delegate = delegate;
        self.theme = [HLTheme sharedInstance];
        textView = [[FDGrowingTextView alloc] init];
        textView.internalTextView.inputAccessoryView = nil;
        textView.textColor = [self.theme inputTextFontColor];
        textView.tintColor = [self.theme inputTextFontColor];
        textView.minNumberOfLines = 1;
        textView.maxNumberOfLines = 4;
        textView.animateHeightChange = NO;
        textView.animationDuration=0;
        textView.backgroundColor = [UIColor clearColor];
        textView.returnKeyType = UIReturnKeyDefault;
        textView.font = [UIFont systemFontOfSize:14.0f];
        textView.delegate = delegate;
        textView.placeholder = HLLocalizedString(@"Message Placeholder Text");
        [textView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [textView.internalTextView setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        UIImage *innerTextViewImage = [UIImage imageNamed:INPUT_BAR_INNER_TEXT_VIEW_IMAGE];
        UIImage *outerTextViewImage = [UIImage imageNamed:INPUT_BAR_OUTER_TEXT_VIEW_IMAGE];
        
        innerImageView = [[UIImageView alloc] initWithImage:[innerTextViewImage stretchableImageWithLeftCapWidth:13 topCapHeight:22]];
        innerImageView.translatesAutoresizingMaskIntoConstraints = NO;
        
        outerImageView = [[UIImageView alloc] initWithImage:[outerTextViewImage stretchableImageWithLeftCapWidth:13 topCapHeight:22]];
        outerImageView.translatesAutoresizingMaskIntoConstraints = NO;
        
        attachButton = [FDButton buttonWithType:UIButtonTypeCustom];
        attachButton.translatesAutoresizingMaskIntoConstraints = NO;
        UIImage *attachmentImage = [UIImage imageNamed:INPUT_BAR_ATTACHMENT_IMAGE];
        [attachButton setImage:attachmentImage forState:UIControlStateNormal];
        [attachButton addTarget:self action:@selector(attachmentButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        sendButton = [FDButton buttonWithType:UIButtonTypeSystem];
        sendButton.translatesAutoresizingMaskIntoConstraints = NO;
        [sendButton setTitle:HLLocalizedString(@"Send Button Text") forState:UIControlStateNormal];
        [sendButton setTitleColor:[self.theme sendButtonColor] forState:UIControlStateNormal];
        [sendButton addTarget:self action:@selector(sendButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        //View hierarchy
        [outerImageView addSubview:innerImageView];
        [self addSubview:outerImageView];
        [self addSubview:textView];
        [self addSubview:attachButton];
        [self addSubview:sendButton];
    }
    return self;
}

-(void)attachmentButtonAction:(id)sender{
    [self.delegate inputToolbarAttachmentButtonPressed:sender];
}

-(void)sendButtonAction:(id)sender{
    [self.delegate inputToolbarSendButtonPressed:sender];
}

-(void)layoutSubviews{
    NSMutableDictionary *views = [NSMutableDictionary dictionaryWithDictionary:NSDictionaryOfVariableBindings(attachButton, outerImageView, sendButton, innerImageView)];
    views[@"internalTextView"] = textView.internalTextView;
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[outerImageView]|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[outerImageView]|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[sendButton(27)]" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[attachButton]" options:0 metrics:nil views:views]];
    [outerImageView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[innerImageView]|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[attachButton]-[innerImageView]-[sendButton(63)]-5-|" options:0 metrics:nil views:views]];
    [textView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[internalTextView]|" options:0 metrics:nil views:views]];
    [textView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[internalTextView]|" options:0 metrics:nil views:views]];
    
    attachButtonWidthConstraint = [NSLayoutConstraint constraintWithItem:attachButton
                                                               attribute:NSLayoutAttributeWidth
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:nil
                                                               attribute:NSLayoutAttributeNotAnAttribute
                                                              multiplier:1.0
                                                                constant:0.0];
    
    if (self.canShowAttachButton) {
        attachButtonWidthConstraint.constant = 40.0;
    }
    
    [self addConstraint:attachButtonWidthConstraint];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:textView
                                                              attribute:NSLayoutAttributeLeading
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:innerImageView
                                                              attribute:NSLayoutAttributeLeading
                                                             multiplier:1.0
                                                               constant:1.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:textView
                                                              attribute:NSLayoutAttributeHeight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:innerImageView
                                                              attribute:NSLayoutAttributeHeight
                                                             multiplier:1.0
                                                               constant:0.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:textView
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:innerImageView
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1.0
                                                               constant:5.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:textView
                                                              attribute:NSLayoutAttributeTrailing
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:innerImageView
                                                              attribute:NSLayoutAttributeTrailing
                                                             multiplier:1.0
                                                               constant:0.0]];
    
    [super layoutSubviews];
}

-(void)enableSendButton:(BOOL)state{
    self.sendButton.enabled = state;
    if (state) {
        [self.sendButton setTitleColor:[self.theme sendButtonColor] forState:UIControlStateNormal];
    }else{
        [self.sendButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    }
}

-(void)showAttachButton:(BOOL)state{
    self.canShowAttachButton = state;
}

@end