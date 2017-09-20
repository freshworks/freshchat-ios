//
//  FDAttachmentImageController.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 03/12/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDAttachmentImageController.h"
#import "FDInputToolbarView.h"
#import "Konotor.h"
#import "FDBarButtonItem.h"
#import "FCTheme.h"
#import "HLLocalization.h"
#import "FDAutolayoutHelper.h"
#import "FDLocalNotification.h"

@interface FDAttachmentImageController ()

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) FDInputToolbarView *inputToolbar;
@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic) CGRect viewFrame;
@end

@implementation FDAttachmentImageController

-(instancetype)initWithImage:(UIImage *)image{
    self = [super init];
    if (self) {
        self.image = image;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNavigationItem];
    self.navigationItem.title = HLLocalizedString(LOC_PIC_MSG_ATTACHMENT_TITLE_TEXT);
    self.view.backgroundColor = [UIColor whiteColor];
    self.imageView = [[UIImageView alloc]initWithImage:self.image];
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.keyboardHeight = 0;
    self.viewFrame = CGRectNull;
    self.inputToolbar = [[FDInputToolbarView alloc]initWithDelegate:self];
    self.inputToolbar.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputToolbar.isFromAttachmentScreen = YES;
    [self setHeightForTextView:self.inputToolbar.textView];
    [self.inputToolbar prepareView];
    
    [self.view addSubview:self.inputToolbar];
    [self.view addSubview:self.imageView];
    
    NSDictionary *views = @{ @"imageView"        : self.imageView,
                             @"inputToolbar"         : self.inputToolbar };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[imageView]-10-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[inputToolbar]-0-|" options:0 metrics:nil views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[imageView(>=0)]-10-[inputToolbar(43)]-0-|" options:0 metrics:nil views:views]];
    [self localNotificationSubscription];
    
}

-(void)inputToolbar:(FDInputToolbarView *)toolbar attachmentButtonPressed:(id)sender {
    
}
-(void)inputToolbar:(FDInputToolbarView *)toolbar sendButtonPressed:(id)sender {
    [self sendMessage];
}
-(void)inputToolbar:(FDInputToolbarView *)toolbar micButtonPressed:(id)sender {
    
}

-(void)inputToolbar:(FDInputToolbarView *)toolbar textViewDidChange:(UITextView *)textView{
    [self setHeightForTextView:textView];
}

-(void)setHeightForTextView:(UITextView *)textView{
    CGFloat NUM_OF_LINES = 2;
    CGFloat MAX_HEIGHT = textView.font.lineHeight * NUM_OF_LINES;    
    CGFloat preferredTextViewHeight = 0;
    CGFloat messageHeight = [textView sizeThatFits:CGSizeMake(textView.frame.size.width, CGFLOAT_MAX)].height;
    if(messageHeight > MAX_HEIGHT)
    {
        preferredTextViewHeight = MAX_HEIGHT;
        textView.scrollEnabled=YES;
    }
    else{
        preferredTextViewHeight = messageHeight;
        textView.scrollEnabled=NO;
    }
    textView.frame=CGRectMake(textView.frame.origin.x, textView.frame.origin.y, textView.frame.size.width, preferredTextViewHeight);
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(void)localNotificationSubscription {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self localNotificationUnSubscription];
}

-(void)localNotificationUnSubscription {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];// this will do the trick
}


-(void)setNavigationItem{
    
    self.navigationController.navigationBar.titleTextAttributes = @{
                                                                    NSForegroundColorAttributeName: [[FCTheme sharedInstance] navigationBarTitleColor],
                                                                    NSFontAttributeName: [[FCTheme sharedInstance] navigationBarTitleFont]
                                                                    };
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:HLLocalizedString(LOC_PIC_MSG_ATTACHMENT_CLOSE_BTN) style:UIBarButtonItemStylePlain target:self action:@selector(dismissPresentedView)];
    
    [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil] setTitleTextAttributes:
     @{UITextAttributeTextColor:[[FCTheme sharedInstance] imgAttachBackButtonFontColor],
       UITextAttributeTextShadowOffset:[NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
       UITextAttributeTextShadowColor:[UIColor whiteColor],
       UITextAttributeFont:[[FCTheme sharedInstance] imgAttachBackButtonFont]
       }
                                                                                            forState:UIControlStateNormal];
    
    self.navigationItem.leftBarButtonItem = backButton;
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.barTintColor = [[FCTheme sharedInstance ]navigationBarBackgroundColor];
}

-(void)sendMessage {
    [self dismissPresentedView];
    if(self.delegate){
        NSCharacterSet *trimChars = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSString *toSend = [self.inputToolbar.textView.text stringByTrimmingCharactersInSet:trimChars];
        if (([toSend isEqualToString:@""]) || ([toSend isEqualToString:HLLocalizedString(LOC_MESSAGE_PLACEHOLDER_TEXT)])) {
            toSend = @"";
        }
        [self.delegate attachmentController:self didFinishSelectingImage:self.image withCaption:toSend];
    }
}

- (void) dismissPresentedView {
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark Orientation Change delegate


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
}


#pragma mark Keyboard delegate

-(void) keyboardWillShow:(NSNotification *)notification {
    if(CGRectIsNull(self.viewFrame) || self.keyboardHeight == 0) {
        self.viewFrame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    }
    CGRect keyboardFrame = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardRect = [self.view convertRect:keyboardFrame fromView:nil];
    self.keyboardHeight = keyboardRect.size.height;
    self.view.frame = CGRectMake(self.view.frame.origin.x , (self.viewFrame.origin.y - self.keyboardHeight), self.view.frame.size.width, self.view.frame.size.height);
}

-(void) keyboardWillHide:(NSNotification *)notification {
    self.view.frame = CGRectMake(self.view.frame.origin.x , self.viewFrame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    self.keyboardHeight = 0;
}

-(void)dealloc{
    self.inputToolbar.delegate = nil;
}


@end
