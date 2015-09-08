//
//  FDAttachmentImageViewController.m
//  FreshdeskSDK
//
//  Created by balaji on 27/10/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDAttachmentImageViewController.h"
#import "FDKit.h"
#import <QuartzCore/QuartzCore.h>
#import "FDProgressHUD.h"
#import "FDReachability.h"
#import "FDMacros.h"
#import "FDUtilities.h"

@interface FDAttachmentImageViewController () <FDGrowingTextViewDelegate> {
    CGFloat keyBoardHeight;
    CGFloat screenHeight;
    CGRect previousRect;
}

@property (nonatomic, strong) FDTheme            *theme;
@property (nonatomic, strong) UIScrollView       *parentView;
@property (nonatomic, strong) FDGrowingTextView  *captionView;
@property (nonatomic, strong) UIImage            *pickedImage;
@property (nonatomic        ) BOOL               isFirstLaunch;
@property (nonatomic        ) CGRect             keyboardFrame;
@property (nonatomic, strong) UIImageView        *pickedImageView;
@property (nonatomic, strong) UIView             *imageViewBGView;
@property (nonatomic, strong) NSLayoutConstraint *containerBottomConstraint;
@property (nonatomic, strong) NSLayoutConstraint *containerHeightConstraint;
@property (strong, nonatomic) FDReachability     *reachability;
@property (strong, nonatomic) FDBarButtonItem    *sendButton;
@property (nonatomic)         CGRect             aspectFrame;

@end

@implementation FDAttachmentImageViewController

@synthesize parentView, imageViewBGView, pickedImage, pickedImageView, captionView, containerBottomConstraint, containerHeightConstraint, isFirstLaunch, keyboardFrame, aspectFrame;

#pragma mark - Lazy Instantiations

-(instancetype)initWithPickedImage:(UIImage *)pickedImageFromGallery {
    self = [super init];
    if (self) {
        self.pickedImage = pickedImageFromGallery;
    }
    return self;
}

-(FDTheme *)theme{
    if(!_theme){
        _theme = [FDTheme sharedInstance];
    }
    return _theme;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    previousRect = CGRectZero;
    keyBoardHeight = 0;
    isFirstLaunch = YES;
    [self setupNavigationItems];
    [self initViews];
    [self updateConstraintsForKeyboardPresent];
    [self localNotificationSubscription];
    [self checkNetworkReachability];
}

-(void)checkNetworkReachability{
    self.reachability = [FDReachability reachabilityWithHostname:@"www.google.com"];
    __weak typeof(self)weakSelf = self;
    FDButton *sendButtonInternal = (FDButton *)self.sendButton.customView;
    
    //Reachable Network
    self.reachability.reachableBlock = ^(FDReachability *reach){
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.sendButton.enabled = YES;
            [sendButtonInternal setTitleColor:[weakSelf.theme navigationBarButtonColor] forState:UIControlStateNormal];
        });
    };
    
    //Unreachable Network
    self.reachability.unreachableBlock = ^(FDReachability *reach){
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.sendButton.enabled = NO;
            [sendButtonInternal setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        });
    };
    
    [self.reachability startNotifier];
}


- (void)setupNavigationItems {
    self.navigationController.navigationBar.translucent = NO;
    self.title = FDLocalizedString(@"Attachment View Nav Bar Title Text");
    //Right Bar Button Item
    self.sendButton = [[FDBarButtonItem alloc] initWithTitle:FDLocalizedString(@"Attachment View Right Bar Button Text" ) style: UIBarButtonItemStylePlain target: self action: @selector(sendNoteButton:)];
    [self.navigationItem setRightBarButtonItem:self.sendButton];
}

- (void)updateConstraintsForKeyboardPresent {
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:parentView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:parentView
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeading
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:parentView
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:parentView
                                                          attribute:NSLayoutAttributeTrailing
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTrailing
                                                         multiplier:1.0
                                                           constant:0.0]];


    //mainImageBGView
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:imageViewBGView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:imageViewBGView
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeading
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:imageViewBGView
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:containerView
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0
                                                           constant:-40.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:imageViewBGView
                                                          attribute:NSLayoutAttributeTrailing
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTrailing
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    //pickedImageView
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:pickedImageView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:imageViewBGView
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:5.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:pickedImageView
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:imageViewBGView
                                                          attribute:NSLayoutAttributeLeading
                                                         multiplier:1.0
                                                           constant:5.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:pickedImageView
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:imageViewBGView
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0
                                                           constant:-5.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:pickedImageView
                                                          attribute:NSLayoutAttributeTrailing
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:imageViewBGView
                                                          attribute:NSLayoutAttributeTrailing
                                                         multiplier:1.0
                                                           constant:-5.0]];

    
    //containerView
    [self.view addConstraint:containerBottomConstraint];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:containerView
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeading
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:containerHeightConstraint];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:containerView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    //image view
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:imageView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:containerView
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:imageView
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:containerView
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:imageView
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:containerView
                                                          attribute:NSLayoutAttributeLeading
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:imageView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:containerView
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    
    //entry image view
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:entryImageView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:imageView
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:entryImageView
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:imageView
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:entryImageView
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeading
                                                         multiplier:1.0
                                                           constant:10.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:entryImageView
                                                          attribute:NSLayoutAttributeTrailing
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTrailing
                                                         multiplier:1.0
                                                           constant:-5.0]];
    
    //text view
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:captionView
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:entryImageView
                                                          attribute:NSLayoutAttributeLeading
                                                         multiplier:1.0
                                                           constant:1.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:captionView
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:entryImageView
                                                          attribute:NSLayoutAttributeHeight
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:captionView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:entryImageView
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:3.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:captionView
                                                          attribute:NSLayoutAttributeTrailing
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:entryImageView
                                                          attribute:NSLayoutAttributeTrailing
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    //INTERNAL TEXT VIEW
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:captionView.internalTextView
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:captionView
                                                          attribute:NSLayoutAttributeLeading
                                                         multiplier:1.0
                                                           constant:1.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:captionView.internalTextView
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:captionView
                                                          attribute:NSLayoutAttributeHeight
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:captionView.internalTextView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:captionView
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:captionView.internalTextView
                                                          attribute:NSLayoutAttributeTrailing
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:captionView
                                                          attribute:NSLayoutAttributeTrailing
                                                         multiplier:1.0
                                                           constant:0.0]];
}

- (void)initViews {
    if (isFirstLaunch == YES) {
        if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
                screenHeight = self.view.bounds.size.width;
            }else {
                screenHeight = self.view.bounds.size.height;
            }
        }else {
            screenHeight = self.view.bounds.size.height;
        }
    }else {
        screenHeight = self.view.bounds.size.height;
    }
    
    isFirstLaunch = NO;
    
    parentView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    [parentView setTranslatesAutoresizingMaskIntoConstraints:NO];
    parentView.backgroundColor = [self.theme backgroundColorSDK];
    parentView.contentSize = CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height+1.0);
    parentView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [parentView setShowsVerticalScrollIndicator:NO];
    [self.view addSubview:parentView];
    
    imageViewBGView = [[UIView alloc] initWithFrame:CGRectZero];
    [imageViewBGView setTranslatesAutoresizingMaskIntoConstraints:NO];
    imageViewBGView.backgroundColor = [UIColor clearColor];
    [parentView addSubview:imageViewBGView];
    
    pickedImageView = [[UIImageView alloc] initWithImage:pickedImage];
    pickedImageView.contentMode = UIViewContentModeScaleAspectFit;
    [pickedImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [imageViewBGView addSubview:pickedImageView];
    
    containerView = [[UIView alloc] init];
    [containerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    containerHeightConstraint = [NSLayoutConstraint constraintWithItem:containerView
                                                             attribute:NSLayoutAttributeHeight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:nil
                                                             attribute:NSLayoutAttributeNotAnAttribute
                                                            multiplier:1.0
                                                              constant:40.0];
    
    containerBottomConstraint = [NSLayoutConstraint constraintWithItem:containerView
                                                             attribute:NSLayoutAttributeBottom
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.view
                                                             attribute:NSLayoutAttributeBottom
                                                            multiplier:1.0
                                                              constant:keyBoardHeight];
    
    captionView = [[FDGrowingTextView alloc] init];
    captionView.textColor = [self.theme inputTextFontColor];
    captionView.tintColor = [self.theme inputTextFontColor];
    captionView.minNumberOfLines = 1;
    captionView.maxNumberOfLines = 4;
    captionView.backgroundColor = [UIColor clearColor];
    captionView.returnKeyType = UIReturnKeyDefault;
    captionView.font = [UIFont systemFontOfSize:14.0f];
    captionView.delegate = self;
    captionView.placeholder = FDLocalizedString(@"Message Placeholder Text" );
    [captionView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [captionView.internalTextView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:containerView];
    
    UIImage *rawEntryBackground = [self.theme getThemedImageFromMHBundleWithName:MOBIHELP_IMAGE_MESSAGE_BAR_INNER_TEXT_VIEW];
    UIImage *entryBackground = [rawEntryBackground stretchableImageWithLeftCapWidth:13 topCapHeight:22];
    entryImageView = [[UIImageView alloc] initWithImage:entryBackground];
    [entryImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    UIImage *rawBackground = [self.theme getThemedImageFromMHBundleWithName:MOBIHELP_IMAGE_MESSAGE_BAR_OUTER_TEXT_VIEW];
    UIImage *background = [rawBackground stretchableImageWithLeftCapWidth:13 topCapHeight:22];
    imageView = [[UIImageView alloc] initWithImage:background];
    [imageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    // view hierachy
    [containerView addSubview:imageView];
    [containerView addSubview:captionView];
    [containerView addSubview:entryImageView];
}

- (void)sendNoteButton:(id)sender{
    [self dismissKeyboards];
    FDNoteContent *noteContent = [[FDNoteContent alloc]init];
    noteContent.body = [self getAttachmentDescription];
    noteContent.imageData = UIImageJPEGRepresentation(pickedImage,0.3);
    [self.delegate attachmentController:self didFinishEditingContent:noteContent withCompletion:^(NSError *error) {
        if (!error) {
            [FDProgressHUD showSuccessWithStatus:FDLocalizedString(@"Attachment success Alert Text")];
            [self dismissControllerWithDelay:1.0];
        }else{
            [FDProgressHUD showErrorWithStatus:@"No internet access please try after some time"];
        }
    }];
}

-(NSString *)getAttachmentDescription{
    if (captionView.text && [captionView.text length] > 0 ) {
        return captionView.text;
    }else{
        return FDLocalizedString(@"Image Attached");
    }
}

-(void)dismissKeyboards{
    [self.view endEditing:YES];
}

-(void)dismissControllerWithDelay:(CGFloat)delay{
    double delayInSeconds   = delay;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [FDProgressHUD dismiss];
        [self dismissKeyboards];
        [self dismissViewControllerAnimated: YES completion: nil];
    });
}

#pragma mark - Growing TextView Delegates

- (void)growingTextView:(FDGrowingTextView *)growingTextView willChangeHeight:(float)height{
    if (height > containerHeightConstraint.constant) {
        containerHeightConstraint.constant = height;
        containerBottomConstraint.constant = - keyBoardHeight;
    }
}

- (void)growingTextViewDidChange:(FDGrowingTextView *)growingTextView {
    if ([growingTextView.text isEqualToString:@""]) {
        containerHeightConstraint.constant = 40.0;
        containerBottomConstraint.constant = - keyBoardHeight;
    }
}

#pragma mark - Keyboard Delegates

-(void) keyboardWillShow:(NSNotification *)note{
    NSTimeInterval animationDuration = [[note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    self.keyboardFrame = [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
            keyBoardHeight = self.keyboardFrame.size.width;
        }else {
            keyBoardHeight = self.keyboardFrame.size.height;
        }
    }else {
        keyBoardHeight = self.keyboardFrame.size.height;
    }
    
    screenHeight = self.view.bounds.size.height;
    containerBottomConstraint.constant = -keyBoardHeight;
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}

-(void) keyboardWillHide:(NSNotification *)note{
    NSTimeInterval animationDuration = [[note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    keyBoardHeight = 0.0;
    screenHeight = self.view.bounds.size.height;
    containerBottomConstraint.constant = 0;
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}

-(void)localNotificationSubscription{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

-(void)localNotificationUnSubscription{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(CGSize)imageSizeAfterAspectFit:(UIImageView*)imgview{
    
    
    float newwidth;
    float newheight;
    
    UIImage *image=imgview.image;
    
    if (image.size.height>=image.size.width){
        newheight=imgview.frame.size.height;
        newwidth=(image.size.width/image.size.height)*newheight;
        
        if(newwidth>imgview.frame.size.width){
            float diff=imgview.frame.size.width-newwidth;
            newheight=newheight+diff/newheight*newheight;
            newwidth=imgview.frame.size.width;
        }
        
    }
    else{
        newwidth=imgview.frame.size.width;
        newheight=(image.size.height/image.size.width)*newwidth;
        
        if(newheight>imgview.frame.size.height){
            float diff=imgview.frame.size.height-newheight;
            newwidth=newwidth+diff/newwidth*newwidth;
            newheight=imgview.frame.size.height;
        }
    }
    
    //adapt UIImageView size to image size
    aspectFrame = CGRectMake(imgview.frame.origin.x+(imgview.frame.size.width-newwidth)/2,imgview.frame.origin.y+(imgview.frame.size.height-newheight)/2,newwidth,newheight);
    
    return CGSizeMake(newwidth, newheight);
    
}

@end