//
//  KonotorImageInput.m
//  KonotorDemo
//
//  Created by Srikrishnan Ganesan on 10/03/14.
//  Copyright (c) 2014 Demach. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "KonotorImageInput.h"
#import <QuartzCore/QuartzCore.h>
#import "FDAttachmentImageController.h"
#import "HLMacros.h"
#import "HLLocalization.h"
#import "FDSecureStore.h"


@interface KonotorImageInput () <FDAttachmentImageControllerDelegate, UIPopoverControllerDelegate>{
    
    BOOL isCameraCaptureEnabled;
}

@property (strong, nonatomic) UIView* sourceView;
@property (strong, nonatomic) UIViewController* sourceViewController;
@property (strong, nonatomic) UIImage* imagePicked;
@property (strong, nonatomic) UIPopoverController* popover;

@property (nonatomic, strong) KonotorConversation *conversation;
@property (nonatomic, strong) HLChannel *channel;
@property (nonatomic, strong) FDAttachmentImageController *imageController;

@end

@implementation KonotorImageInput

@synthesize sourceView,sourceViewController,imagePicked,popover;

- (instancetype)initWithConversation:(KonotorConversation *)conversation onChannel:(HLChannel *)channel{
    self = [super init];
    if (self) {
        self.conversation = conversation;
        self.channel = channel;
    }
    return self;
}

- (void) showInputOptions:(UIViewController*) viewController{
   
    FDSecureStore *store = [FDSecureStore sharedInstance];
    isCameraCaptureEnabled = [store boolValueForKey:HOTLINE_DEFAULTS_CAMERA_CAPTURE_ENABLED];
    NSArray *actionButtons;
    if(isCameraCaptureEnabled){
        actionButtons = @[HLLocalizedString(LOC_IMAGE_ATTACHMENT_EXISTING_IMAGE_BUTTON_TEXT),HLLocalizedString(LOC_IMAGE_ATTACHMENT_NEW_IMAGE_BUTTON_TEXT)];
    }
    else{
        actionButtons = @[HLLocalizedString(LOC_IMAGE_ATTACHMENT_EXISTING_IMAGE_BUTTON_TEXT)];
    }
    
    UIActionSheet *inputOptions = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:HLLocalizedString(LOC_IMAGE_ATTACHMENT_CANCEL_BUTTON_TEXT)
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
    
    for (NSString *actionTitle in actionButtons) {
        [inputOptions addButtonWithTitle:actionTitle];
    }
    inputOptions.delegate = self;
    self.sourceViewController=viewController;
    self.sourceView=viewController.view;
    [inputOptions showInView:self.sourceView];
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (buttonIndex) {
        case 1:
            [self showImagePicker];
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

- (void) showAccessDeniedAlert{
    
    UIAlertView *permissionAlert = [[UIAlertView alloc] initWithTitle:nil message:HLLocalizedString(LOC_CAMERA_PERMISSION_DENIED_TEXT) delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
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
    self.imageController = [[FDAttachmentImageController alloc]initWithImage:selectedImage];
    self.imageController.delegate = self;
    self.imagePicked = selectedImage;
    UINavigationController *navcontroller = [[UINavigationController alloc] initWithRootViewController:self.imageController];
    [self.sourceViewController presentViewController:navcontroller animated:YES completion:nil];
}

-(void)attachmentController:(FDAttachmentImageController *)controller didFinishSelectingImage:(UIImage *)image withCaption:(NSString *)caption {
    [Konotor uploadNewImage:self.imagePicked withCaption:caption onConversation:self.conversation onChannel:self.channel];
}

@end
