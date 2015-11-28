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

@interface KonotorImageInput ()

@property (nonatomic, strong) KonotorConversation *conversation;
@property (nonatomic, strong) HLChannel *channel;

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


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
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


- (void)showCamPicker
{
    UIImagePickerController* imagePicker=[[UIImagePickerController alloc] init];
    [imagePicker setAllowsEditing:NO];
    imagePicker.delegate=self;
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self.sourceViewController presentViewController:imagePicker animated:YES completion:NULL];
        });
    }
    else{
        UIAlertView *alertview=[[UIAlertView alloc] initWithTitle:@"Camera Unavailable" message:@"Sorry! Your device doesn't have a camera, or the camera is not available for use." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertview show];
    }
}

- (void)showImagePicker
{
    UIImagePickerController* imagePicker=[[UIImagePickerController alloc] init];
    [imagePicker setAllowsEditing:NO];
    imagePicker.delegate=self;
    [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        popover=[[UIPopoverController alloc] initWithContentViewController:imagePicker];
        
        dispatch_async(dispatch_get_main_queue(), ^ {
            [popover presentPopoverFromRect:CGRectMake(self.sourceViewController.view.frame.origin.x,self.sourceViewController.view.frame.origin.y+sourceViewController.view.frame.size.height-20,40,40) inView:self.sourceViewController.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        });

    }
    else
        [self.sourceViewController presentViewController:imagePicker animated:YES completion:NULL];
}

- (void) rotateToOrientation:(UIInterfaceOrientation) orientation duration:(NSTimeInterval) duration
{
    if(self.imagePicked){
        UIImage* img=self.imagePicked;
        [self dismissImageSelection];
        
        self.imagePicked=img;
        
        NSDictionary* info=[[NSDictionary alloc] initWithObjectsAndKeys:img,UIImagePickerControllerOriginalImage,nil];
        [self imagePickerController:nil didFinishPickingMediaWithInfo:info];
 
    }
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    float adjustHeight=[KonotorFeedbackScreen sharedInstance].conversationViewController.showingInTab?([KonotorFeedbackScreen sharedInstance].conversationViewController.tabBarHeight):0;
    
    [[sourceViewController navigationController] setNavigationBarHidden:YES animated:NO];
    
    UIImage* selectedImage=(UIImage*)[info valueForKey:UIImagePickerControllerOriginalImage];
    self.imagePicked=selectedImage;
    if((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)&&popover){
        [popover dismissPopoverAnimated:YES];
        popover=nil;
    }
    else
        [picker dismissViewControllerAnimated:NO completion:NULL];

    UIImageView* selectedImageView=[[UIImageView alloc] initWithImage:selectedImage];
    float height=MIN(selectedImage.size.height,([[UIScreen mainScreen] bounds].size.height-100-50)*2);
    float width=MIN(520,selectedImage.size.width*height/selectedImage.size.height);
    float screenHeight,screenWidth;
    
    if(((!picker)&&(![KonotorUtility KonotorIsInterfaceLandscape:(sourceViewController)])&&(!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")))||((picker)&&([KonotorUtility KonotorIsInterfaceLandscape:(sourceViewController)])))
    {
        height=MIN(selectedImage.size.height,([[UIScreen mainScreen] bounds].size.width-100-50)*2);
        width=MIN(520,selectedImage.size.width*height/selectedImage.size.height);
        screenHeight=[[UIScreen mainScreen] bounds].size.width-adjustHeight;
        screenWidth=[[UIScreen mainScreen] bounds].size.height;
    }
    else{
        height=MIN(selectedImage.size.height,([[UIScreen mainScreen] bounds].size.height-100-50)*2);
        width=MIN(520,selectedImage.size.width*height/selectedImage.size.height);
        screenHeight=[[UIScreen mainScreen] bounds].size.height-adjustHeight;
        screenWidth=[[UIScreen mainScreen] bounds].size.width;
    }
    
    height=selectedImage.size.height*width/selectedImage.size.width;
    [selectedImageView setFrame:CGRectMake((screenWidth-width/2)/2, 40+((screenHeight-40-40)-height/2)/2,width/2, height/2)];
    selectedImageView.layer.cornerRadius=15.0;
    
    UIView* alertOptionsBackground=[[UIView alloc] initWithFrame:CGRectMake(0,0,screenWidth,screenHeight)];
    [alertOptionsBackground setBackgroundColor:[UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:0.4]];
    
    alertOptions=[[UIView alloc] initWithFrame:CGRectMake(0,0,screenWidth,screenHeight)];
    [alertOptions setBackgroundColor:[UIColor blackColor]];
    
    [alertOptionsBackground addSubview:alertOptions];
    
    
    UIButton* buttonCancel=[[UIButton alloc] initWithFrame:CGRectMake(0, 14, 36, 36)];
    
    [buttonCancel setImage:[UIImage imageNamed:@"konotor_back.png"] forState:UIControlStateNormal];
    
    if(picker.sourceType==UIImagePickerControllerSourceTypePhotoLibrary)
        [buttonCancel addTarget:self action:@selector(dismissImageSelection) forControlEvents:UIControlEventTouchUpInside];
    else
        [buttonCancel addTarget:self action:@selector(cleanUpImageSelection) forControlEvents:UIControlEventTouchUpInside];
    
    [alertOptions addSubview:buttonCancel];
    [alertOptions bringSubviewToFront:buttonCancel];
    [alertOptions addSubview:selectedImageView];
    
    
    UIButton* send=[[UIButton alloc] initWithFrame:CGRectMake(screenWidth-16-80, screenHeight-45, 80, 45)];
    [send setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [send setTitle:@"Send" forState:UIControlStateNormal];
    [send addTarget:self action:@selector(dismissImageSelectionWithSelectedImage:) forControlEvents:UIControlEventTouchUpInside];
    
    [alertOptions addSubview:send];
    [sourceView addSubview:alertOptionsBackground];
    
}

- (void)registerForKeyboardNotifications

{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}





- (void) cleanupMenuSent
{
    [self cleanUpImageSelection];
}

- (void) dismissImageSelection
{
    [[sourceViewController navigationController] setNavigationBarHidden:NO animated:NO];
    UIView* alertOptionsBackground=[alertOptions superview];
    [alertOptionsBackground removeFromSuperview];
    alertOptions=nil;
    alertOptionsBackground=nil;
    self.imagePicked=nil;
}

- (void) cleanUpImageSelection
{
    [self dismissImageSelection];
    [[sourceViewController navigationController] setNavigationBarHidden:NO animated:NO];
    self.imagePicked=nil;
}

- (void) cleanupMenu
{
    UIView * win=[[[UIApplication sharedApplication] delegate] window];
    UIView* sendLabel=(UIView*)[win viewWithTag:5000];
    UIView* editLabel=(UIView*)[win viewWithTag:5001];
    [sendLabel setHidden:NO];
    [editLabel setHidden:NO];
    [[sourceViewController navigationController] setNavigationBarHidden:NO animated:NO];

}

- (void)dismissImageSelectionWithSelectedImage:(id) sender{
    [Konotor uploadImage:self.imagePicked onConversation:self.conversation onChannel:self.channel];
    [self cleanUpImageSelection];
    self.imagePicked=nil;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    if(popover){
        [popover dismissPopoverAnimated:YES];
        popover=nil;
    }
    else
        [picker dismissViewControllerAnimated:YES completion:NULL];
}



@end
