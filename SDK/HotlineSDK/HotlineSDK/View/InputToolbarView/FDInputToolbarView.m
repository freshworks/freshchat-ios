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
@property (strong, nonatomic) UITextView           *inputTextView;
@property (strong, nonatomic) UIImageView          *innerImageView;
@property (strong, nonatomic) UIImageView          *outerImageView;
@property (nonatomic, strong) NSLayoutConstraint   *attachButtonWidthConstraint;
@property (nonatomic, strong) HLTheme              *theme;
@property (weak, nonatomic) id <FDInputToolbarViewDelegate> delegate;
@property (nonatomic) BOOL canShowAttachButton;

@end

@implementation FDInputToolbarView

@synthesize innerImageView, outerImageView,inputTextView, sendButton, attachButton, attachButtonWidthConstraint;

-(instancetype)initWithDelegate:(id <FDInputToolbarViewDelegate, UITextViewDelegate>)delegate{
    self = [super init];
    if (self) {
        
        self.delegate = delegate;
        self.theme = [HLTheme sharedInstance];
        
        self.backgroundColor=[UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
   
        inputTextView=[[UITextView alloc] init];
        [inputTextView setTextColor:[self.theme inputTextFontColor]];
        inputTextView.layer.borderColor=[[UIColor lightGrayColor] CGColor];
        inputTextView.layer.cornerRadius=5.0;
        inputTextView.layer.borderWidth=1.0;
        [inputTextView setTranslatesAutoresizingMaskIntoConstraints:NO];
        inputTextView.delegate=delegate;

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
        
        [self addSubview:inputTextView];
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
    NSMutableDictionary *views = [NSMutableDictionary dictionaryWithDictionary:NSDictionaryOfVariableBindings(attachButton,inputTextView, sendButton)];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[inputTextView]-5-|" options:0 metrics:nil views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[sendButton(27)]-5-|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[attachButton]|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[attachButton]-[inputTextView]-[sendButton(54)]-5-|" options:0 metrics:nil views:views]];
    
    
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