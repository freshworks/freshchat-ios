//
//  KonotorImageInput.m
//  KonotorDemo
//
//  Created by Srikrishnan Ganesan on 10/03/14.
//  Copyright (c) 2014 Demach. All rights reserved.
//

#import "KonotorImageInput.h"
#import "KonotorFeedbackScreen.h"
#import <QuartzCore/QuartzCore.h>
#import "FDAttachmentImageController.h"

@interface KonotorImageInput () <FDAttachmentImageControllerDelegate>

@property (nonatomic, strong) KonotorConversation *conversation;
@property (nonatomic, strong) HLChannel *channel;
@property (nonatomic, strong) FDAttachmentImageController *imageController;

@end

@implementation KonotorImageInput

@synthesize sourceView,alertOptions,sourceViewController,imagePicked,popover;

- (instancetype)initWithConversation:(KonotorConversation *)conversation onChannel:(HLChannel *)channel{
    self = [super init];
    if (self) {
        self.conversation = conversation;
        self.channel = channel;
    }
    return self;
}

- (void) showInputOptions:(UIViewController*) viewController{
    if([[KonotorUIParameters sharedInstance] noPhotoOption]){
        self.sourceViewController=viewController;
        self.sourceView=viewController.view;
        [self showImagePicker];
        return;
    }
    UIActionSheet* inputOptions=[[UIActionSheet alloc] initWithTitle:@"Message Type" delegate:nil cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Select Existing Image",@"New Image via Camera",nil];
    inputOptions.delegate = self;
    self.sourceViewController=viewController;
    self.sourceView=viewController.view;
    [inputOptions showInView:self.sourceView];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (buttonIndex) {
        case 0:
            [self showImagePicker];
            break;
        case 1:
            [self showCamPicker];
            break;
        default:
            break;
    }
}

- (void)showImagePicker{
    UIImagePickerController* imagePicker=[[UIImagePickerController alloc] init];
    imagePicker.delegate=self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.allowsEditing = NO;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        popover=[[UIPopoverController alloc] initWithContentViewController:imagePicker];
        dispatch_async(dispatch_get_main_queue(), ^ {
            [popover presentPopoverFromRect:CGRectMake(self.sourceViewController.view.frame.origin.x,self.sourceViewController.view.frame.origin.y+sourceViewController.view.frame.size.height-20,40,40) inView:self.sourceViewController.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
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
        UIAlertView *alertview=[[UIAlertView alloc] initWithTitle:@"Camera Unavailable" message:@"Sorry! Your device doesn't have a camera, or the camera is not available for use." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertview show];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage* selectedImage = info[UIImagePickerControllerOriginalImage];
    self.imageController = [[FDAttachmentImageController alloc]initWithImage:selectedImage];
    self.imageController.delegate = self;
    self.imagePicked = selectedImage;
    [picker pushViewController:self.imageController animated:YES];
}

-(void)attachmentController:(FDAttachmentImageViewController *)controller didFinishSelectingImage:(UIImage *)image{
    [Konotor uploadImage:self.imagePicked onConversation:self.conversation onChannel:self.channel];
}

@end