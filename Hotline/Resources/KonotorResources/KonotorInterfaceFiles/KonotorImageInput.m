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

static KonotorImageInput* konotorImageInput=nil;

@implementation KonotorImageInput
@synthesize sourceView,alertOptions,sourceViewController,imagePicked,popover;

+ (KonotorImageInput*) sharedInstance
{
    if(konotorImageInput==nil){
        konotorImageInput=[[KonotorImageInput alloc] init];
    }
    return konotorImageInput;
}


+ (void) showInputOptions:(UIViewController*) viewController
{
    
    if([[KonotorUIParameters sharedInstance] noPhotoOption]){
        konotorImageInput.sourceViewController=viewController;
        konotorImageInput.sourceView=viewController.view;
        [[KonotorImageInput sharedInstance] showImagePicker];
        return;
    }
 //   if(!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")){
    UIActionSheet* inputOptions=[[UIActionSheet alloc] initWithTitle:@"Message Type" delegate:nil cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Select Existing Image",@"New Image via Camera",nil];
    inputOptions.delegate=[KonotorImageInput sharedInstance];
    konotorImageInput.sourceViewController=viewController;
    konotorImageInput.sourceView=viewController.view;
    [inputOptions showInView:konotorImageInput.sourceView];
   // }
  /*  else{
    
    UIAlertController* inputOptions2=[UIAlertController alertControllerWithTitle:@"Message Type" message:@"Hi" preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction* action1=[UIAlertAction actionWithTitle:@"Select Existing Image" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[KonotorImageInput sharedInstance] actionSheet:nil clickedButtonAtIndex:0];
    }];
    [inputOptions2 addAction:action1];
        inputOptions2.popoverPresentationController.sourceView=konotorImageInput.sourceView;
    [konotorImageInput.sourceViewController presentViewController:inputOptions2 animated:NO completion:nil];
    }
   */
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  //  [actionSheet dismissWithClickedButtonIndex:buttonIndex animated:NO];
    
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

+ (void) rotateToOrientation:(UIInterfaceOrientation) orientation duration:(NSTimeInterval) duration
{
    if(konotorImageInput.imagePicked){
        UIImage* img=[KonotorImageInput sharedInstance].imagePicked;
        [[KonotorImageInput sharedInstance] dismissImageSelection];
        
        [KonotorImageInput sharedInstance].imagePicked=img;
        
        NSDictionary* info=[[NSDictionary alloc] initWithObjectsAndKeys:img,UIImagePickerControllerOriginalImage,nil];
        [[KonotorImageInput sharedInstance] imagePickerController:nil didFinishPickingMediaWithInfo:info];
 
    }
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
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
        screenHeight=[[UIScreen mainScreen] bounds].size.width;
        screenWidth=[[UIScreen mainScreen] bounds].size.height;
    }
    else{
        height=MIN(selectedImage.size.height,([[UIScreen mainScreen] bounds].size.height-100-50)*2);
        width=MIN(520,selectedImage.size.width*height/selectedImage.size.height);
        screenHeight=[[UIScreen mainScreen] bounds].size.height;
        screenWidth=[[UIScreen mainScreen] bounds].size.width;
    }
    
    height=selectedImage.size.height*width/selectedImage.size.width;
    //float width=selectedImage.size.width*150/selectedImage.size.height;
    [selectedImageView setFrame:CGRectMake((screenWidth-width/2)/2, 40+((screenHeight-40-40)-height/2)/2,width/2, height/2)];
    selectedImageView.layer.cornerRadius=15.0;
    
    UIView* alertOptionsBackground=[[UIView alloc] initWithFrame:CGRectMake(0,0,screenWidth,screenHeight)];
    [alertOptionsBackground setBackgroundColor:[UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:0.4]];
    
    alertOptions=[[UIView alloc] initWithFrame:CGRectMake(0,0,screenWidth,screenHeight)];
    [alertOptions setBackgroundColor:[UIColor blackColor]];
    /*
     alertOptions.layer.cornerRadius=0.0;
    alertOptions.layer.shadowColor=[[UIColor blackColor] CGColor];
    alertOptions.layer.shadowOffset=CGSizeMake(1.0, 1.0);
    alertOptions.layer.shadowRadius=3.0;
    alertOptions.layer.shadowOpacity=1.0;
     */
    
    [alertOptionsBackground addSubview:alertOptions];
    
    
    UIButton* buttonCancel=[[UIButton alloc] initWithFrame:CGRectMake(0, 14, 36, 36)];
    
    [buttonCancel setImage:[UIImage imageNamed:@"konotor_back.png"] forState:UIControlStateNormal];
   // [buttonCancel setTitle:@"X" forState:UIControlStateNormal];
   // [buttonCancel setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
/*    buttonCancel.layer.cornerRadius=15.0;
    buttonCancel.layer.borderWidth=3.5;
    buttonCancel.layer.borderColor=[[UIColor whiteColor] CGColor];
  */
    
    if(picker.sourceType==UIImagePickerControllerSourceTypePhotoLibrary)
        [buttonCancel addTarget:self action:@selector(dismissImageSelection) forControlEvents:UIControlEventTouchUpInside];
    else
        [buttonCancel addTarget:self action:@selector(cleanUpImageSelection) forControlEvents:UIControlEventTouchUpInside];
    
    [alertOptions addSubview:buttonCancel];
    [alertOptions bringSubviewToFront:buttonCancel];
    [alertOptions addSubview:selectedImageView];
    
    
    UIButton* send=[[UIButton alloc] initWithFrame:CGRectMake(screenWidth-16-80, screenHeight-45-(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")?0:20), 80, 45)];
    [send setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [send setTitle:@"Send" forState:UIControlStateNormal];
    [send addTarget:self action:@selector(dismissImageSelectionWithSelectedImage:) forControlEvents:UIControlEventTouchUpInside];
    
   

    UITextField* caption=[[UITextField alloc] initWithFrame:CGRectMake(0, screenHeight-30-45-(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")?0:20), screenWidth, 30)];
    [caption setBackgroundColor:[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.6]];
    [caption setTextColor:[UIColor whiteColor]];
    [caption setText:@"Tap to edit..."];
    [caption setTextAlignment:NSTextAlignmentCenter];
    [caption setTag:KONOTOR_IMAGEINPUT_CAPTIONTEXT];
    
    UITextView* inputView=[[UITextView alloc] initWithFrame:CGRectMake(0, 0,screenWidth, 60)];
    [inputView setBackgroundColor:[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.6]];
    [inputView setTextColor:[UIColor whiteColor]];
    [inputView setText:@""];
    [inputView setHidden:YES];
    [inputView setTag:KONOTOR_IMAGEINPUT_CAPTIONENTRY];
    [inputView setReturnKeyType:UIReturnKeyDone];

    [alertOptions addSubview:inputView];
    
    [self registerForKeyboardNotifications];
    
#if KONOTOR_ENABLECAPTIONS
    [alertOptions addSubview:caption];
#endif
    
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



// Called when the UIKeyboardDidShowNotification is sent.

- (void)keyboardWasShown:(NSNotification*)aNotification

{
    
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    float keyboardHeight=kbSize.height;
    float screenHeight,screenWidth;
    
    if(![KonotorUtility KonotorIsInterfaceLandscape:(sourceViewController)])
    {
        screenWidth=[[UIScreen mainScreen] bounds].size.width;
        screenHeight=[[UIScreen mainScreen] bounds].size.height;
    }
    else{
        screenWidth=[[UIScreen mainScreen] bounds].size.height;
        screenHeight=[[UIScreen mainScreen] bounds].size.width;
        keyboardHeight=kbSize.width;
    }
    
    UITextView* inputView=(UITextView*)[sourceView viewWithTag:KONOTOR_IMAGEINPUT_CAPTIONENTRY];
    
    [inputView setFrame:CGRectMake(0, (screenHeight-keyboardHeight)-60, screenWidth,60)];
    [inputView setHidden:NO];
    [inputView setEnablesReturnKeyAutomatically:YES];
    [inputView becomeFirstResponder];
    [inputView setDelegate:self];

}

- (BOOL) textView: (UITextView*) textView shouldChangeTextInRange: (NSRange) range replacementText: (NSString*) text
{
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}


// Called when the UIKeyboardWillHideNotification is sent

- (void)keyboardWillBeHidden:(NSNotification*)aNotification

{
    UITextView* inputView=(UITextView*)[sourceView viewWithTag:KONOTOR_IMAGEINPUT_CAPTIONENTRY];
    [inputView setHidden:YES];
    
    UITextField* caption=(UITextField*) [sourceView viewWithTag:KONOTOR_IMAGEINPUT_CAPTIONTEXT];
    caption.text=inputView.text;
    
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

   // [self.sourceViewController dismissViewControllerAnimated:NO completion:NULL];
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

- (void) dismissImageSelectionWithSelectedImage:(id) sender
{    
    
//    [(AppDelegate*)[[UIApplication sharedApplication] delegate] sendImage:button.photo forConversation:self.conversation participants:self.participants withSubject:self.conversation.subject withMetrics:nil withPhotoURL:self.conversation.photoURL];
    if(self.imagePicked){
#if KONOTOR_ENABLECAPTIONS
        UITextField* caption=(UITextField*) [sourceView viewWithTag:KONOTOR_IMAGEINPUT_CAPTIONTEXT];
        if( caption && [caption.text isEqualToString:@"Tap to edit..."])
#endif
            [Konotor uploadImage:self.imagePicked];
        
#if KONOTOR_ENABLECAPTIONS
        else
            [Konotor uploadImage:self.imagePicked withCaption:caption.text];
#endif
    }
    [self cleanUpImageSelection];
    [KonotorFeedbackScreen refreshMessages];
    self.imagePicked=nil;

}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    if(popover){
        [popover dismissPopoverAnimated:YES];
        popover=nil;
    }
    else
        [picker dismissViewControllerAnimated:YES completion:NULL];
    //  [self loadViewFirstTime];
}



@end
