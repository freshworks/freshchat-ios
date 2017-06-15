//
//  FDAttachmentImageController.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 03/12/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDAttachmentImageController.h"
#import "Konotor.h"
#import "FDBarButtonItem.h"
#import "HLTheme.h"

@interface FDAttachmentImageController ()

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic) NSNumber *keyboardHeight;
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
    self.view.backgroundColor = [UIColor whiteColor];
    self.imageView = [[UIImageView alloc]initWithImage:self.image];
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.keyboardHeight = 0;
    self.textView = [[UITextView alloc]init];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    //self.textView.text = @"Type Image caption here(Optional)";
    
    [[self.textView layer] setBorderColor:[[UIColor grayColor] CGColor]];
    [[self.textView layer] setBorderWidth:2.3];
    [[self.textView layer] setCornerRadius:15];
    self.textView.textColor = [[HLTheme sharedInstance] inputTextFontColor];
    self.textView.font = [[HLTheme sharedInstance] inputTextFont];
    [self.textView setDelegate:self];
    
    self.placeholderLabel = [[UILabel alloc]init];
    self.placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.placeholderLabel.text = @"Type Image caption here(Optional)";
    
    [self.view addSubview:self.textView];
    //[self.view addSubview:self.placeholderLabel];
    [self.view addSubview:self.imageView];
    
    NSDictionary *views = @{ @"imageView"        : self.imageView,
                             @"textView"         : self.textView };
                             //@"placeholderLabel" : self.placeholderLabel};
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[imageView]-20-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[textView]-20-|" options:0 metrics:nil views:views]];
    //[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[placeholderLabel]-20-|" options:0 metrics:nil views:views]];
    
    //[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[imageView]-10-[placeholderLabel]" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[imageView(>=0)]-10-[textView(50)]-10-|" options:0 metrics:nil views:views]];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];// this will do the trick
}


-(void)setNavigationItem{
    UIBarButtonItem *sendButton = [[FDBarButtonItem alloc]initWithTitle:@"Send" style:UIBarButtonItemStylePlain target:self action:@selector(sendButton:)];
    UIBarButtonItem *backButton = [[FDBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(dismissPresentedView)];
    self.navigationItem.rightBarButtonItem = sendButton;
    self.navigationItem.leftBarButtonItem = backButton;
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.barTintColor = [[HLTheme sharedInstance ]navigationBarBackgroundColor];
}

#pragma mark Text view delegates

- (void)textViewDidChange:(UITextView *)inputTextView{
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (textView == self.textView)
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDuration:0.5];
        [UIView setAnimationBeginsFromCurrentState:YES];
        //self.view.frame = CGRectMake(self.view.frame.origin.x , (self.view.frame.origin.y + 80), self.view.frame.size.width, self.view.frame.size.height);
        [UIView commitAnimations];
    }
}


- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if (textView == self.textView)
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDuration:0.5];
        [UIView setAnimationBeginsFromCurrentState:YES];
        //self.view.frame = CGRectMake(self.view.frame.origin.x , (self.view.frame.origin.y - 80), self.view.frame.size.width, self.view.frame.size.height);
        [UIView commitAnimations];
    }
}

-(void)keyboardWasShown:(NSNotification *)notification {
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    int height = MIN(keyboardSize.height,keyboardSize.width);
    self.keyboardHeight = [[NSNumber alloc] initWithInt:height];
    
    if (self.view.frame.origin.y >= 0)
    {
        [self setViewMovedUp:YES];
    }
    else if (self.view.frame.origin.y < 0)
    {
        [self setViewMovedUp:NO];
    }
}

-(void)keyboardWillHide {
    if (self.view.frame.origin.y >= 0)
    {
        [self setViewMovedUp:YES];
    }
    else if (self.view.frame.origin.y < 0)
    {
        [self setViewMovedUp:NO];
    }
}

-(void)setViewMovedUp:(BOOL)movedUp
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    
    CGRect rect = self.view.frame;
    if (movedUp)
    {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        
        self.view.frame = CGRectMake(self.view.frame.origin.x , (self.view.frame.origin.y - [self.keyboardHeight floatValue]), self.view.frame.size.width, self.view.frame.size.height);
        
        //rect.origin.y -= [self.keyboardHeight floatValue];
        //rect.size.height += [self.keyboardHeight floatValue];
    }
    else
    {
        self.view.frame = CGRectMake(self.view.frame.origin.x , (self.view.frame.origin.y + [self.keyboardHeight floatValue]), self.view.frame.size.width, self.view.frame.size.height);
        
        // revert back to the normal state.
        //rect.origin.y += [self.keyboardHeight floatValue];
        //rect.size.height -= [self.keyboardHeight floatValue];
    }
    //self.view.frame = rect;
    
    [UIView commitAnimations];
}



-(void)sendButton:(UIBarButtonItem *)button{
    
    [self dismissPresentedView];
    if(self.delegate){
        [self.delegate attachmentController:self didFinishSelectingImage:self.image withCaption:self.textView.text];
    }
}

- (void) dismissPresentedView {
    [self dismissViewControllerAnimated:NO completion:nil];
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return self.imageView;
}

@end
