//
//  FDNewTicketViewController.m
//  FreshdeskSDK
//
//  Created by balaji on 29/04/14.
//  Copyright (c) 2014 balaji. All rights reserved.
//

#import "FDAPIClient.h"
#import "MobiHelpDatabase.h"
#import "FDCoreDataImporter.h"
#import "FDProgressHUD.h"
#import "FDSecureStore.h"
#import "Mobihelp.h"
#import "FDKit.h"
#import "FDNewTicketViewController.h"
#import "FDNoteListViewController.h"
#import "FDFolderListViewController.h"
#import "FDTicketListViewController.h"
#import "FDReachability.h"
#import "FDUtilities.h"
#import "MobihelpAppState.h"
#import "FDError.h"
#import "FDTicketContent.h"
#import "FDUserInfoForm.h"
//#import <AssetsLibrary/ALAssetsLibrary.h>
//#import <AssetsLibrary/ALAssetsFilter.h>
//#import <AssetsLibrary/ALAssetRepresentation.h>
#import "FDCoreDataCoordinator.h"

@interface FDNewTicketViewController ()

@property (nonatomic) FEEDBACK_TYPE feedbackType;
@property (nonatomic, strong) FDUserInfoForm *userInfoForm;
@property (nonatomic, strong) FDPlaceholderTextView *ticketBodyField;
@property (nonatomic, strong) UIImageView *pickedImageView;
@property (nonatomic, strong) FDButton *attachmentButton;
@property (nonatomic, strong) FDButton *imageRemoveButton;
@property (strong, nonatomic) FDCoreDataImporter *coreDataImporter;
@property (strong, nonatomic) FDTheme *theme;
@property (strong, nonatomic) FDSecureStore *secureStore;
@property (strong, nonatomic) FDReachability *reachability;
@property (strong, nonatomic) FDBarButtonItem *submitButton;
@property (nonatomic) BOOL isModalView;
@property (nonatomic) CGFloat keyBoardHeight;
@property (nonatomic, strong) NSLayoutConstraint *attachmentButtonHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *pickedImageViewHeightConstraint;
@property (strong, nonatomic) NSLayoutConstraint *userInfoFieldBottomConstraint;

@end

@implementation FDNewTicketViewController

static NSString *cachedTicketDescription;

@synthesize ticketBodyField, attachmentButton, userInfoForm,
pickedImageView, imageRemoveButton, userInfoFieldBottomConstraint,
attachmentButtonHeightConstraint, pickedImageViewHeightConstraint, keyBoardHeight;

#pragma mark - Lazy Instantiations

-(instancetype)initWithModalPresentationType:(BOOL)isModalPresentation {
    self = [super init];
    if (self) {
        self.isModalView = isModalPresentation;
        self.theme = [FDTheme sharedInstance];
        self.secureStore = [FDSecureStore sharedInstance];
        self.feedbackType = [FDUtilities getFeedBackType];
    }
    return self;
}

-(FDCoreDataImporter *)coreDataImporter{
    if(!_coreDataImporter){
        FDAPIClient *webservice = [[FDAPIClient alloc]init];
        _coreDataImporter  = [[FDCoreDataImporter alloc]
                              initWithContext:[[FDCoreDataCoordinator sharedInstance] mainContext] webservice:webservice];
    }
    return _coreDataImporter;
}

#pragma mark - View Controller Initializations

- (void)viewDidLoad{
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self setBackgroundColor];
    [self setNavigationItem];
    [self setSubviews];
    [self subviewConfig];
    [self setLayoutConstraints];
    [self checkIfEnhancedPrivacyEnabled];
    [self checkNetworkReachability];
    [self localNotificationSubscription];
    [self prepopulateTicketBody];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [ticketBodyField becomeFirstResponder];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [FDProgressHUD dismiss];
    [self cacheTicketDescription];
}

-(void)setBackgroundColor{
    self.view.backgroundColor = [self.theme backgroundColorSDK];
}

-(void)localNotificationSubscription{
    [self setupKeyboardNotifications];
}

#pragma mark Cache ticket description

-(void)prepopulateTicketBody{
    if (self.ticketDescription) {
        self.ticketBodyField.text = self.ticketDescription;
    }else{
        self.ticketBodyField.text = cachedTicketDescription;
    }
}

-(void)clearCachedTicketDescription{
    cachedTicketDescription = nil;
    self.ticketBodyField.text = nil;
}

-(void)cacheTicketDescription{
    cachedTicketDescription = self.ticketBodyField.text;
}

-(void)checkNetworkReachability{
    self.reachability = [FDReachability reachabilityWithHostname:@"www.google.com"];
    __weak typeof(self)weakSelf = self;
    FDButton *submitButtonInternal = (FDButton *)self.submitButton.customView;

    //Reachable Network
    self.reachability.reachableBlock = ^(FDReachability *reach){
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.submitButton.enabled = YES;
            [submitButtonInternal setTitleColor:[weakSelf.theme navigationBarButtonColor] forState:UIControlStateNormal];
        });
    };
    
    //Unreachable Network
    self.reachability.unreachableBlock = ^(FDReachability *reach){
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.submitButton.enabled = NO;
            [submitButtonInternal setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        });
    };
    [self.reachability startNotifier];
}

-(void)subviewConfig{
    keyBoardHeight = 0;
    pickedImageView.hidden = YES;
    imageRemoveButton.hidden = YES;
}

-(BOOL)hasPresetUserInfo{
    NSString *presetName  = [FDUtilities getUserName];
    NSString *presetEmail = [FDUtilities getEmailAddress];
    if( self.feedbackType == FEEDBACK_TYPE_NAME_AND_EMAIL_REQUIRED )
        return presetName && presetEmail;
    if( self.feedbackType == FEEDBACK_TYPE_NAME_REQUIRED_AND_EMAIL_OPTIONAL )
        return (presetName? YES:NO);
    if( self.feedbackType == FEEDBACK_TYPE_ANONYMOUS )
        return YES;
    return NO;
}

#pragma mark - Navigation Stack

-(void)setNavigationItem{
    self.title = FDLocalizedString(@"New Ticket Nav Bar Title Text" );
    //Left Bar Button
    if (self.isModalView) {
        FDBarButtonItem * backButton = [[FDBarButtonItem alloc] initWithTitle:FDLocalizedString(@"Back Button Text" ) style: UIBarButtonItemStyleBordered target: self action: @selector(backButton:)];
        self.navigationItem.leftBarButtonItem = backButton;
    }
    
    //Right Bar Button
    self.submitButton = [[FDBarButtonItem alloc] initWithTitle:FDLocalizedString(@"Submit Button Text" ) style: UIBarButtonItemStyleBordered target: self action: @selector(submitButtonPressed)];
    self.navigationItem.rightBarButtonItem = self.submitButton;
}

- (void)backButton:(id)sender{
    [self dismissKeyboards];
    [self dismissViewControllerAnimated: YES completion: nil];
}

-(void)dismissKeyboards{
    [self.view endEditing:YES];
}

- (void)submitButtonPressed{
    BOOL isAppValid = [[MobihelpAppState sharedMobihelpAppState] isAppDisabled];
    BOOL isRegisteredUser = [FDUtilities isRegisteredUser];
    if (isAppValid) {
        if ([self isFormValid]) {
            [FDProgressHUD showWithStatus:FDLocalizedString(@"Submitting HUD Text" ) maskType:FDProgressHUDMaskTypeClear];
            if (!isRegisteredUser) [self saveUserInformation];
            [self postNewTicket];
        }
    }else{
        [FDProgressHUD showErrorWithStatus:FDLocalizedString(@"app disabled error message")];
    }
}

-(void)saveUserInformation{
    NSString *submittedUsername = [self.userInfoForm getUserName];
    NSString *submittedEmail    = [self.userInfoForm getEmailAddress];
    if ([submittedUsername length] > 0) {
        [self.secureStore setObject:submittedUsername forKey:MOBIHELP_DEFAULTS_USER_NAME];
    }
    if ([submittedEmail length] > 0){
        [self.secureStore setObject:submittedEmail forKey:MOBIHELP_DEFAULTS_USER_EMAIL_ADDRESS];
    }
}

-(void)postNewTicket{
    ShowNetworkActivityIndicator();
    if([FDUtilities isRegisteredUser]){
        [self postNewTicketRequest];
    }
    else{
        [self.coreDataImporter registerUserWithCompletion:^(NSError* error){
            if(error){
                NSLog(@"Failed to create ticket %@",error);
                [self showError:error];
                HideNetworkActivityIndicator();
            }
            else {
                [self postNewTicketRequest];
            }
        }];
    }
}

-(void)postNewTicketRequest{
    FDTicketContent *ticketContent = [self constructTicketContent];
    [self.coreDataImporter createTicketWithContent:ticketContent completion:^(FDTicket *ticket, NSError *error) {
        if (!error) {
            //Show success message then dismiss
            [FDProgressHUD showSuccessWithStatus:FDLocalizedString(@"Ticket Submitted Successfully Text")];
            [self dismissKeyboards];
            [self navigateToConversationViewWithTicket:ticket afterDelay:0.5];
            [self clearCachedTicketDescription];
        }else{
            NSLog(@"Failed to send ticket Request %@",error);
            [self showError:error];
        }
        HideNetworkActivityIndicator();
    }];
}

-(FDTicketContent *)constructTicketContent{
    FDTicketContent *ticketContent = [[FDTicketContent alloc]init];
    NSString *ticketSubject = nil;
    NSString *ticketBody = [FDUtilities sanitizeStringForUTF8:self.ticketBodyField.text];
    if ([ticketBody length] <= 80) {
        ticketSubject = ticketBody;
    }else {
        ticketSubject = [ticketBody substringToIndex:50];
    }
    ticketSubject = [FDUtilities sanitizeStringForNewLineCharacter:ticketSubject];
    ticketContent.ticketSubject = ticketSubject;
    ticketContent.ticketBody = ticketBody;
    ticketContent.imageData = UIImageJPEGRepresentation(self.pickedImageView.image,0.3);
    return ticketContent;
}

-(void)showError:(NSError *)error{
    if ([error isKindOfClass:[FDError class]]) {
        FDError *MHError = (FDError *)error;
        if ([FDError isAppDisabledForError:MHError]) {
            [FDProgressHUD showErrorWithStatus:FDLocalizedString(@"app disabled error message")];
        }else if(MHError.code == MOBIHELP_ERROR_NETWORK_CONNECTIVITY){
            [FDProgressHUD showErrorWithStatus:FDLocalizedString(@"Network Error Message")];
        }else{
            [FDProgressHUD showErrorWithStatus:FDLocalizedString(@"Ticket Submission Error Text" )];
        }
    }else{
        [FDProgressHUD showErrorWithStatus:FDLocalizedString(@"Ticket Submission Error Text" )];
    }
}

-(void)navigateToConversationViewWithTicket:(FDTicket *)ticket afterDelay:(CGFloat)delay{
    double delayInSeconds = delay;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        FDNoteListViewController *noteListController = [[FDNoteListViewController alloc]initWithTicketID:ticket.ticketID];
        if (!self.isModalView) {
            if ([self.sourceController isKindOfClass:[FDFolderListViewController class]]) {
                FDTicketListViewController *ticketListController = [[FDTicketListViewController alloc]init];
                [self.sourceController.navigationController popToRootViewControllerAnimated:NO];
                [self.sourceController.navigationController pushViewController:ticketListController animated:NO];
                [self.sourceController.navigationController pushViewController:noteListController animated:YES];
            }else if([self.sourceController isKindOfClass:[FDTicketListViewController class]]){
                [self.sourceController.navigationController popViewControllerAnimated:NO];
                [self.sourceController.navigationController pushViewController:noteListController animated:YES];
            }
        }else{
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    });
}

#pragma mark - Form Validation

-(BOOL)isFormValid{
    if ([FDUtilities isRegisteredUser]) {
        return [self checkTicketBodyValidation];
    }
    return [self checkTicketBodyValidation]  && [self.userInfoForm isValid];
}

-(BOOL)checkTicketBodyValidation{
    if ([self isTicketBodyValid]) {
        return YES;
    }else{
        [FDProgressHUD showErrorWithStatus:FDLocalizedString(@"Ticket Body Empty Alert Message Text" )];
        return NO;
    }
}

-(BOOL)isTicketBodyValid{
    return [trimString(self.ticketBodyField.text) length] > 0 && ![self.ticketBodyField.text isEqualToString:FDLocalizedString(@"Ticket Content Placeholder Text" )] ;
}

#pragma mark - Keyboard Listeners

- (void)setupKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

-(void) keyboardWillShow:(NSNotification *)note{
    CGRect keyboardFrame = [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardRect = [self.view convertRect:keyboardFrame fromView:nil];
    CGFloat keyboardCoveredHeight = self.view.bounds.size.height - keyboardRect.origin.y;
    userInfoFieldBottomConstraint.constant = - keyboardCoveredHeight;
    [self.view layoutIfNeeded];
}

-(void) keyboardWillHide:(NSNotification *)note{
    NSTimeInterval animationDuration = [[note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    userInfoFieldBottomConstraint.constant = 0;
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - Initializing and setting subviews

- (void)setSubviews {

    //Ticket body 
    ticketBodyField = [[FDPlaceholderTextView alloc] init];
    ticketBodyField.inputAccessoryView = nil;
    ticketBodyField.translatesAutoresizingMaskIntoConstraints = NO;
    ticketBodyField.tintColor = [self.theme feedbackViewFontColor];
    ticketBodyField.backgroundColor = [self.theme feedbackViewTicketBodyBackgroundColor];
    ticketBodyField.font = [UIFont fontWithName:[self.theme feedbackViewFontName] size:[self.theme feedbackViewFontSize]];
    ticketBodyField.textColor = [self.theme feedbackViewFontColor];
    ticketBodyField.placeholderColor = [self.theme feedbackViewTicketBodyPlaceholderColor];
    ticketBodyField.placeholderText = FDLocalizedString(@"Ticket Content Placeholder Text");
    
    attachmentButton = [FDButton buttonWithType:UIButtonTypeCustom];
    attachmentButton.translatesAutoresizingMaskIntoConstraints = NO;
    UIImage *attachmentPinImage = [self.theme getThemedImageFromMHBundleWithName:MOBIHELP_IMAGE_MESSAGE_BAR_ATTACHMENT_PIN];
    [attachmentButton setImage:attachmentPinImage forState:UIControlStateNormal];
    [attachmentButton addTarget:self action:@selector(attachmentButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    pickedImageView = [[UIImageView alloc] init];
    pickedImageView.contentMode = UIViewContentModeScaleAspectFill;
    pickedImageView.layer.masksToBounds = YES;
    pickedImageView.layer.cornerRadius = 5;
    pickedImageView.userInteractionEnabled = YES;
    pickedImageView.translatesAutoresizingMaskIntoConstraints = NO;
    pickedImageView.layer.cornerRadius = 5.0f;
    
    imageRemoveButton = [FDButton buttonWithType:UIButtonTypeSystem];
    imageRemoveButton.translatesAutoresizingMaskIntoConstraints = NO;
    imageRemoveButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [imageRemoveButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [imageRemoveButton setTitle:FDLocalizedString(@"Attachment Remove Button") forState:UIControlStateNormal];
    [imageRemoveButton addTarget:self action:@selector(removePickedImageView:) forControlEvents:UIControlEventAllTouchEvents];
    
    userInfoForm = [[FDUserInfoForm alloc]initWithName:[FDUtilities getUserName] withEmail:[FDUtilities getEmailAddress] andFeedBackType:self.feedbackType];
    userInfoForm.translatesAutoresizingMaskIntoConstraints = NO;
    
    //View Hierarchy
    [self.view addSubview:ticketBodyField];
    [self.view addSubview:userInfoForm];
    [self.view addSubview:attachmentButton];
    [self.view addSubview:pickedImageView];
    [self.view addSubview:imageRemoveButton];
}

#pragma mark - Layout Contraints

- (void)setLayoutConstraints{
    NSDictionary *views = NSDictionaryOfVariableBindings(ticketBodyField, attachmentButton, pickedImageView, imageRemoveButton, userInfoForm);
    NSDictionary *metrics = nil;
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[ticketBodyField]|" options:0 metrics:metrics views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[ticketBodyField]" options:0 metrics:metrics views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[userInfoForm]|" options:0 metrics:metrics views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[attachmentButton(44)]" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[attachmentButton]-5-[userInfoForm]" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[pickedImageView(50)]-15-[imageRemoveButton]" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[pickedImageView(50)]-10-[userInfoForm]" options:0 metrics:nil views:views]];
   
    NSLayoutConstraint *ticketBodyBottomConstraint = [NSLayoutConstraint constraintWithItem:ticketBodyField
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.userInfoForm
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1.0 constant:0];
    
    attachmentButtonHeightConstraint = [NSLayoutConstraint constraintWithItem:attachmentButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil
                                                                    attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:44.0];
    pickedImageViewHeightConstraint = [NSLayoutConstraint constraintWithItem:pickedImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil
                                                                   attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:50.0];
    
    
    NSInteger userInfoFieldHeight = 0;
    if([FDUtilities isRegisteredUser] || [self hasPresetUserInfo]) {
        userInfoFieldHeight = 0;
        self.userInfoForm.hidden = YES;
    }else{
        userInfoFieldHeight = 35;
    }
    
    NSLayoutConstraint *userInfoFieldHeightConstraint = [NSLayoutConstraint constraintWithItem:self.userInfoForm
                                                                                     attribute:NSLayoutAttributeHeight
                                                                                     relatedBy:NSLayoutRelationEqual
                                                                                        toItem:nil
                                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                                    multiplier:1.0 constant:userInfoFieldHeight];
    userInfoFieldBottomConstraint = [NSLayoutConstraint constraintWithItem:self.userInfoForm attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
    
    
    [self.view addConstraint:userInfoFieldBottomConstraint];
    [self.view addConstraint:userInfoFieldHeightConstraint];
    [self.view addConstraint:ticketBodyBottomConstraint];
    [self.view addConstraint:attachmentButtonHeightConstraint];
    [self.view addConstraint:pickedImageViewHeightConstraint];
}

-(void)checkIfEnhancedPrivacyEnabled{
    BOOL isEnhancedPrivacyEnabled = [[FDSecureStore sharedInstance] boolValueForKey:MOBIHELP_DEFAULTS_IS_ENHANCED_PRIVACY_ENABLED];
    if (isEnhancedPrivacyEnabled) {
        [attachmentButton removeFromSuperview];
        [pickedImageView removeFromSuperview];
    }else{
        ticketBodyField.contentInset = UIEdgeInsetsMake(0, 0, attachmentButtonHeightConstraint.constant, 0);
    }
}


-(NSAttributedString *)attributedStringForPlaceholder:(NSString *)string{
    UIColor *textPlaceHolderColor = [self.theme feedbackViewUserFieldPlaceholderColor];
    return [[NSAttributedString alloc] initWithString:string attributes:@{ NSForegroundColorAttributeName: textPlaceHolderColor}];
}

#pragma mark - Image Picker Delegates

-(void)attachmentButtonPressed:(id)sender{
    [self showPhotoGallery];
}

- (void)showAttachmentOptions:(id)sender {
    UIActionSheet *actionSheetOptions = [[UIActionSheet alloc] initWithTitle:FDLocalizedString(@"Attachment Options Text") delegate:self cancelButtonTitle:FDLocalizedString(@"Attachment Cancel Button Text") destructiveButtonTitle:nil otherButtonTitles:FDLocalizedString(@"Use Last Taken Photo Text"),FDLocalizedString(@"Open Photo Gallery Text"), nil];
    [actionSheetOptions showInView:[UIApplication sharedApplication].keyWindow];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
//        [self chooseLastPhoto];
    }
    if (buttonIndex == 1) {
        [self showPhotoGallery];
    }
}

//- (void)chooseLastPhoto {
//    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//
//    // Enumerate just the photos and videos group by using ALAssetsGroupSavedPhotos.
//    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
//        
//        // Within the group enumeration block, filter to enumerate just photos.
//        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
//        
//        // Chooses the photo at the last index
//        [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *alAsset, NSUInteger index, BOOL *innerStop) {
//            
//            // The end of the enumeration is signaled by asset == nil.
//            if (alAsset) {
//                ALAssetRepresentation *representation = [alAsset defaultRepresentation];
//                UIImage *latestPhoto = [UIImage imageWithCGImage:[representation fullScreenImage]];
//                
//                // Stop the enumerations
//                *stop = YES; *innerStop = YES;
//                
//                self.attachmentButton.hidden = YES;
//                self.pickedImageView.hidden = NO;
//                self.imageRemoveButton.hidden = NO;
//                ticketBodyField.contentInset = UIEdgeInsetsMake(0, 0, pickedImageViewHeightConstraint.constant, 0);
//                self.pickedImageView.image = latestPhoto;
//                [ticketBodyField becomeFirstResponder];
//            }
//        }];
//    } failureBlock: ^(NSError *error) {
//        // Typically you should handle an error more gracefully than this.
//        NSLog(@"No groups");
//    }];
//}

- (void)showPhotoGallery {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.view.backgroundColor = [self.theme backgroundColorSDK];
    [FDProgressHUD show];
    [self presentViewController:picker animated:YES completion:^{
        [FDProgressHUD dismiss];
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage * pickedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:nil];
    self.attachmentButton.hidden = YES;
    self.pickedImageView.hidden = NO;
    self.imageRemoveButton.hidden = NO;
    self.pickedImageView.image = pickedImage;
    ticketBodyField.contentInset = UIEdgeInsetsMake(0, 0, pickedImageViewHeightConstraint.constant, 0);
}

- (void)removePickedImageView:(id)sender {
    self.attachmentButton.hidden = NO;
    self.pickedImageView.hidden = YES;
    self.imageRemoveButton.hidden = YES;
    ticketBodyField.contentInset = UIEdgeInsetsMake(0, 0, attachmentButtonHeightConstraint.constant, 0);
}

@end