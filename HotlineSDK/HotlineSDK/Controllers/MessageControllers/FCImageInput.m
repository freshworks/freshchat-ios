//
//  KonotorImageInput.m
//  KonotorDemo
//
//  Created by Srikrishnan Ganesan on 10/03/14.
//  Copyright (c) 2014 Demach. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "FCImageInput.h"
#import <QuartzCore/QuartzCore.h>
#import "FCAttachmentImageController.h"
#import "FCMacros.h"
#import "FCLocalization.h"
#import "FCSecureStore.h"
#import "FCRemoteConfig.h"
#import "FCUserUtil.h"
#import "Photos/Photos.h"

@interface FCImageInput () <FDAttachmentImageControllerDelegate, UIPopoverControllerDelegate>{
    BOOL isCameraCaptureEnabled;
    BOOL isGallerySelectionEnabled;
}

@property (strong, nonatomic) UIView* sourceView;
@property (strong, nonatomic) UIViewController* sourceViewController;
@property (strong, nonatomic) UIImage* imagePicked;
@property (strong, nonatomic) UIPopoverController* popover;

@property (nonatomic, strong) FCConversations *conversation;
@property (nonatomic, strong) FCChannels *channel;
@property (nonatomic, strong) FCAttachmentImageController *imageController;
@property (nonatomic, strong) UIActionSheet *inputOptions;

@end

@implementation FCImageInput

@synthesize sourceView,sourceViewController,imagePicked,popover;

- (instancetype)initWithConversation:(FCConversations *)conversation onChannel:(FCChannels *)channel{
    self = [super init];
    if (self) {
        self.conversation = conversation;
        self.channel = channel;
    }
    return self;
}

- (void) showInputOptions:(UIViewController*) viewController{
   
    if(![[FCRemoteConfig sharedInstance] isActiveInboxAndAccount]){
        return;
    }
    FCSecureStore *store = [FCSecureStore sharedInstance];
    isCameraCaptureEnabled = [store boolValueForKey:HOTLINE_DEFAULTS_CAMERA_CAPTURE_ENABLED];
    isGallerySelectionEnabled = [store boolValueForKey:HOTLINE_DEFAULTS_GALLERY_SELECTION_ENABLED];
    NSArray *actionButtons;
    self.inputOptions = [[UIActionSheet alloc] initWithTitle:nil
                                                              delegate:self
                                                     cancelButtonTitle:HLLocalizedString(LOC_IMAGE_ATTACHMENT_CANCEL_BUTTON_TEXT)
                                                destructiveButtonTitle:nil
                                                     otherButtonTitles:nil];
    if(isCameraCaptureEnabled && isGallerySelectionEnabled){
        actionButtons = @[HLLocalizedString(LOC_IMAGE_ATTACHMENT_EXISTING_IMAGE_BUTTON_TEXT),HLLocalizedString(LOC_IMAGE_ATTACHMENT_NEW_IMAGE_BUTTON_TEXT)];
        self.inputOptions.tag = 0;
    }
    else if(isCameraCaptureEnabled){
        actionButtons = @[HLLocalizedString(LOC_IMAGE_ATTACHMENT_NEW_IMAGE_BUTTON_TEXT)];
        self.inputOptions.tag = 2;
    }
    else if(isGallerySelectionEnabled){
        actionButtons = @[HLLocalizedString(LOC_IMAGE_ATTACHMENT_EXISTING_IMAGE_BUTTON_TEXT)];
        self.inputOptions.tag = 1;
    }
    
    for (NSString *actionTitle in actionButtons) {
        [self.inputOptions addButtonWithTitle:actionTitle];
    }
    self.inputOptions.delegate = self;
    self.sourceViewController=viewController;
    self.sourceView=viewController.view;
    [self.inputOptions showInView:self.sourceView];
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSInteger actionInput = (actionSheet.tag > 0 && buttonIndex) ? actionSheet.tag : buttonIndex;
    switch (actionInput) {
        case 1:
            [self checkLibraryAccessPermission];
            break;
        case 2:
            [self checkCameraCapturePermission];
            break;
        default:
            break;
    }
}

- (void)popoverController:(UIPopoverController *)popoverController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView *__autoreleasing *)view
{
    CGRect rectInView = CGRectMake(self.sourceViewController.view.frame.origin.x,self.sourceViewController.view.frame.origin.y+sourceViewController.view.frame.size.height-20,40,40);
    *rect = CGRectMake(CGRectGetMidX(rectInView), CGRectGetMaxY(rectInView)-40, 1, 1);
    *view = self.sourceViewController.view;
    
}

- (void)checkCameraCapturePermission{
    
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(status == AVAuthorizationStatusAuthorized) {
        [self showCamPicker];
    } else if(status == AVAuthorizationStatusDenied){
        // denied
        [self showAccessDeniedAlert];
    } else if(status == AVAuthorizationStatusRestricted){
        // restricted
        [self showAccessDeniedAlert];
    } else if(status == AVAuthorizationStatusNotDetermined){
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if(granted){
                //user granted
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showCamPicker];
                });
                
            } else {
                //user denied
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showAccessDeniedAlert];
                });
            }
        }];
    }
}

- (void)checkLibraryAccessPermission{
    
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    
    if (status == PHAuthorizationStatusAuthorized) {
        [self showImagePicker];
    }
    
    else if (status == PHAuthorizationStatusDenied) {
        [self showLibAccessDeniedAlert];
    }
    
    else if (status == PHAuthorizationStatusNotDetermined) {
        
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self checkLibraryAccessPermission];
            });
        }];
    }
    
    else if (status == PHAuthorizationStatusRestricted) {
        // Restricted access - normally won't happen.
        [self showLibAccessDeniedAlert];
    }
}

- (void) showAccessDeniedAlert{
    
    UIAlertView *permissionAlert = [[UIAlertView alloc] initWithTitle:nil message:HLLocalizedString(LOC_CAMERA_PERMISSION_DENIED_TEXT) delegate:nil cancelButtonTitle:HLLocalizedString(LOC_CAMERA_PERMISSION_ALERT_CANCEL) otherButtonTitles:nil, nil];
    [permissionAlert show];
}

- (void) showLibAccessDeniedAlert{
    UIAlertView *permissionAlert = [[UIAlertView alloc] initWithTitle:nil message:HLLocalizedString(LOC_PHOTO_LIBRARY_PERMISSION_DENIED_TEXT) delegate:nil cancelButtonTitle:HLLocalizedString(LOC_PHOTO_LIBRARY_PERMISSION_ALERT_CANCEL) otherButtonTitles:nil, nil];
    [permissionAlert show];
}

- (void)showImagePicker{
    UIImagePickerController* imagePicker=[[UIImagePickerController alloc] init];
    imagePicker.delegate=self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.allowsEditing = NO;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        popover=[[UIPopoverController alloc] initWithContentViewController:imagePicker];
        popover.delegate = self;
        dispatch_async(dispatch_get_main_queue(), ^ {
            [popover presentPopoverFromRect:CGRectMake(self.sourceViewController.view.frame.origin.x,self.sourceViewController.view.frame.origin.y+sourceViewController.view.frame.size.height-20,40,40) inView:self.sourceViewController.view permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
        });
    }else{
        [self.sourceViewController presentViewController:imagePicker animated:YES completion:NULL];
    }
}

- (void)showCamPicker{
    
    UIImagePickerController* imagePicker=[[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.allowsEditing = NO;
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self.sourceViewController presentViewController:imagePicker animated:YES completion:NULL];
            
        });
    }else{
        UIAlertView *alertview=[[UIAlertView alloc] initWithTitle:HLLocalizedString(LOC_CAMERA_UNAVAILABLE_TITLE) message:HLLocalizedString(LOC_CAMERA_UNAVAILABLE_DESCRIPTION) delegate:nil
                                                cancelButtonTitle:HLLocalizedString(LOC_CAMERA_UNAVAILABLE_OK_BUTTON) otherButtonTitles:nil];
        [alertview show];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    
    [picker dismissViewControllerAnimated:NO completion:nil];
    UIImage* selectedImage = info[UIImagePickerControllerOriginalImage];
    self.imageController = [[FCAttachmentImageController alloc]initWithImage:selectedImage];
    self.imageController.delegate = self;
    self.imagePicked = selectedImage;
    UINavigationController *navcontroller = [[UINavigationController alloc] initWithRootViewController:self.imageController];
    [self.sourceViewController presentViewController:navcontroller animated:YES completion:nil];
}

- (void) dismissAttachmentActionSheet{
    [self.inputOptions dismissWithClickedButtonIndex:0 animated:YES];
}

-(void)attachmentController:(FCAttachmentImageController *)controller didFinishSelectingImage:(UIImage *)image withCaption:(NSString *)caption {
    
    [FCMessageHelper uploadMessageWithImage:self.imagePicked textFeed:caption onConversation:self.conversation andChannel:self.channel];
}

@end
