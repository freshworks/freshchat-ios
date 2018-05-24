//
//  ViewController.m
//  Hotline
//
//  Created by AravinthChandran on 9/7/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "ViewController.h"
#import "FreshchatSDK/FreshchatSDK.h"
#import "FDSettingsController.h"
#import "AppDelegate.h"
#import "SampleController.h"
#define kOFFSET_FOR_KEYBOARD 160.0
#define SAMPLE_STORYBOARD_CONTROLLER @"SampleController"

@interface ViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *chatButton;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) NSURL *soundUrl;

@property (nonatomic, strong) IBOutlet UITextField *faqTagsField1;
@property (nonatomic, strong) IBOutlet UITextField *faqTagsField2;
@property (nonatomic, strong) IBOutlet UITextField *faqTitleField1;
@property (nonatomic, strong) IBOutlet UITextField *faqTitleField2;
@property (nonatomic, strong) IBOutlet UITextField *faqContactUsTagsField1;
@property (nonatomic, strong) IBOutlet UITextField *faqContactUsTagsField2;
@property (nonatomic, strong) IBOutlet UITextField *faqContactUsTitleField1;
@property (nonatomic, strong) IBOutlet UITextField *faqContactUsTitleField2;

@property (nonatomic, strong) IBOutlet UITextField *conversationTitle;
@property (nonatomic, strong) IBOutlet UITextField *conversationTags;
@property (nonatomic, strong) IBOutlet UITextField *convContactUsTags;
@property (nonatomic, strong) IBOutlet UITextField *convContactUsTitle;

@property (nonatomic, strong) IBOutlet UITextField *message;
@property (nonatomic, strong) IBOutlet UITextField *sendMessageTag;

@property (nonatomic, strong) IBOutlet UISwitch *mysWitch;
@property (nonatomic, strong) IBOutlet UISwitch *myGridSwitch;

@property (nonatomic, assign) BOOL switchVal;

@property (nonatomic, assign) BOOL gridval;

@end

@implementation ViewController

- (void)viewDidLoad {
    self.switchVal = true;
    self.gridval = true;
    [self setupSubview];
    
    self.view.backgroundColor = [UIColor colorWithHue:0 saturation:0 brightness:0.95 alpha:1];
    [super viewDidLoad];
    NSLog(@"~~Current User :Restore-ID  %@", [FreshchatUser sharedInstance].restoreID);
    NSLog(@"~~Current User :Identifier  %@", [FreshchatUser sharedInstance].externalID);
    
    
    self.faqTagsField1.delegate = self;
    self.faqTagsField2.delegate = self;
    self.faqTitleField1.delegate = self;
    self.faqTitleField2.delegate = self;
    self.faqContactUsTagsField1.delegate = self;
    self.faqContactUsTagsField2.delegate = self;
    self.faqContactUsTitleField1.delegate = self;
    self.faqContactUsTitleField2.delegate = self;
    self.conversationTitle.delegate = self;
    self.conversationTags.delegate = self;
    self.message.delegate = self;
    self.sendMessageTag.delegate = self;
    //[[Freshchat sharedInstance] updateConversationBannerMessage:@"123"];

    // Construct URL to sound file
    NSString *path = [NSString stringWithFormat:@"%@/youraudio.mp3", [[NSBundle mainBundle] resourcePath]];
    _soundUrl = [NSURL fileURLWithPath:path];
    
    // Create audio player object and initialize with URL to sound
    if(_soundUrl){
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:_soundUrl error:nil];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveHLPlayNotification:)
                                                 name:FRESHCHAT_DID_FINISH_PLAYING_AUDIO_MESSAGE
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveHLPauseNotification:)
                                                 name:FRESHCHAT_WILL_PLAY_AUDIO_MESSAGE
                                               object:nil];
    
}

- (void) receiveHLPlayNotification:(NSNotification *) notification{
    if(_soundUrl){
        [_audioPlayer play];
    }
}

- (void) receiveHLPauseNotification:(NSNotification *) notification{
    if(_soundUrl){
        [_audioPlayer pause];
    }
}

-(void)setupSubview{
    self.imageView = [[UIImageView alloc]init];
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view insertSubview:self.imageView atIndex:0];
    
//    NSDictionary *views = @{@"imgView" : self.imageView};
    
}

-(void)keyboardWillShow {
    // Animate the current view out of the way
    if (self.view.frame.origin.y >= 0)
    {
        [self setViewMovedUp:YES];
    }
    else if (self.view.frame.origin.y < 0)
    {
        [self setViewMovedUp:NO];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
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

-(void)textFieldDidEndEditing:(UITextField *)sender

{
    //move the main view, so that the keyboard does not hide it.
    if  (self.view.frame.origin.y < 0)
    {
        [self setViewMovedUp:NO];
    }
}



-(void)textFieldDidBeginEditing:(UITextField *)sender
{
    if ([sender isEqual:self.faqTitleField1]||[sender isEqual:self.faqTitleField2]||[sender isEqual:self.faqTagsField1]||[sender isEqual:self.faqTagsField2]||[sender isEqual:self.faqContactUsTagsField1]||[sender isEqual:self.faqContactUsTagsField2]||[sender isEqual:self.faqContactUsTitleField1]||[sender isEqual:self.faqContactUsTitleField2])
    {
        //move the main view, so that the keyboard does not hide it.
        if  (self.view.frame.origin.y >= 0)
        {
            [self setViewMovedUp:YES];
        }
    }
}

//method to move the view up/down whenever the keyboard is shown/dismissed
-(void)setViewMovedUp:(BOOL)movedUp
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    
    CGRect rect = self.view.frame;
    if (movedUp)
    {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        rect.origin.y -= kOFFSET_FOR_KEYBOARD;
        rect.size.height += kOFFSET_FOR_KEYBOARD;
    }
    else
    {
        // revert back to the normal state.
        rect.origin.y += kOFFSET_FOR_KEYBOARD;
        rect.size.height -= kOFFSET_FOR_KEYBOARD;
    }
    self.view.frame = rect;
    
    [UIView commitAnimations];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    if(![_audioPlayer isPlaying]){
        [_audioPlayer play];
    }
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.pickedImage) {
        self.imageView.image = appDelegate.pickedImage;
    }else{
        //self.imageView.image = [UIImage imageNamed:@"background"];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}
SampleController *sampleController;
- (IBAction)chatButtonPressed:(id)sender {
    if(sampleController == nil) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:SAMPLE_STORYBOARD_CONTROLLER bundle:nil];
        sampleController = [sb instantiateViewControllerWithIdentifier:SAMPLE_STORYBOARD_CONTROLLER];
    }
    [self presentViewController:sampleController animated:YES completion:nil];
}

- (IBAction)articleFilter1:(id)sender{
    NSArray *arr = [self.faqTagsField1.text componentsSeparatedByString:@","];
    NSMutableArray *contactUsTagsArray =[[NSMutableArray alloc] initWithArray:[self.faqContactUsTagsField1.text componentsSeparatedByString:@","]];
    [contactUsTagsArray removeObject:@""];
    FAQOptions *options = [FAQOptions new];
    options.showFaqCategoriesAsGrid = self.gridval;
    options.showContactUsOnFaqScreens = self.switchVal;
    options.showContactUsOnAppBar = true;
    if(contactUsTagsArray.count){
        [options filterContactUsByTags:contactUsTagsArray withTitle:self.faqContactUsTitleField1.text];
    }
    [options filterByTags:arr withTitle:self.faqTitleField1.text andType: ARTICLE];
    [[Freshchat sharedInstance]showFAQs:self withOptions:options];
}

- (IBAction)categoryFilter1:(id)sender{
    NSArray *arr = [self.faqTagsField1.text componentsSeparatedByString:@","];
    NSMutableArray *contactUsTagsArray =[[NSMutableArray alloc] initWithArray:[self.faqContactUsTagsField1.text componentsSeparatedByString:@","]];
    [contactUsTagsArray removeObject:@""];
    FAQOptions *options = [FAQOptions new];
    options.showFaqCategoriesAsGrid = self.gridval;
    options.showContactUsOnFaqScreens = self.switchVal;
    if(contactUsTagsArray.count){
        [options filterContactUsByTags:contactUsTagsArray withTitle:self.faqContactUsTitleField1.text];
    }
    [options filterByTags:arr withTitle:self.faqTitleField1.text andType: CATEGORY];
    [[Freshchat sharedInstance]showFAQs:self withOptions:options];
}


- (IBAction)channelFilter1:(id)sender{
    
    NSArray *arr = [self.conversationTags.text componentsSeparatedByString:@","];
    ConversationOptions *opt = [ConversationOptions new];
    [opt filterByTags:arr withTitle:self.conversationTitle.text];
    FAQOptions *options = [FAQOptions new];
    options.showContactUsOnAppBar = true;
    options.showContactUsOnFaqScreens = true;
    NSMutableArray *contactUsTagsArray =[[NSMutableArray alloc] initWithArray:[self.convContactUsTags.text componentsSeparatedByString:@","]];
    [contactUsTagsArray removeObject:@""];
    if(contactUsTagsArray.count){
        [options filterContactUsByTags:contactUsTagsArray withTitle:self.convContactUsTitle.text];
    }
    //[[Freshchat sharedInstance] showConversations:self withOptions:opt];
    UIViewController *viewController = [[Freshchat sharedInstance] getConversationsControllerForEmbedWithOptions:opt];
    [self.navigationController pushViewController:viewController animated:true];
    
    
}

- (IBAction)channelFilter2:(id)sender{
    NSArray *arr = [self.conversationTags.text componentsSeparatedByString:@","];
    ConversationOptions *opt = [ConversationOptions new];
    [opt filterByTags:arr withTitle:self.conversationTitle.text];
    FAQOptions *options = [FAQOptions new];
    options.showContactUsOnAppBar = true;
    options.showContactUsOnFaqScreens = true;
    NSMutableArray *contactUsTagsArray =[[NSMutableArray alloc] initWithArray:[self.convContactUsTags.text componentsSeparatedByString:@","]];
    [contactUsTagsArray removeObject:@""];
    if(contactUsTagsArray.count){
        [options filterContactUsByTags:contactUsTagsArray withTitle:self.convContactUsTitle.text];
    }
    [[Freshchat sharedInstance] showConversations:self withOptions:opt];
}

//2
- (IBAction)articleFilter2:(id)sender{
    NSArray *arr = [self.faqTagsField2.text componentsSeparatedByString:@","];
    NSMutableArray *contactUsTagsArray =[[NSMutableArray alloc] initWithArray:[self.faqContactUsTagsField2.text componentsSeparatedByString:@","]];
    [contactUsTagsArray removeObject:@""];
    FAQOptions *options = [FAQOptions new];
    options.showFaqCategoriesAsGrid = self.gridval;
    options.showContactUsOnFaqScreens = self.switchVal;
    if(contactUsTagsArray.count){
        [options filterContactUsByTags:contactUsTagsArray withTitle:self.faqContactUsTitleField2.text];
    }
    [options filterByTags:arr withTitle:self.faqTitleField2.text andType: ARTICLE];
    [[Freshchat sharedInstance]showFAQs:self withOptions:options];
}

- (IBAction)categoryFilter2:(id)sender{
    NSArray *arr = [self.faqTagsField2.text componentsSeparatedByString:@","];
    NSMutableArray *contactUsTagsArray =[[NSMutableArray alloc] initWithArray:[self.faqContactUsTagsField2.text componentsSeparatedByString:@","]];
    [contactUsTagsArray removeObject:@""];
    FAQOptions *options = [FAQOptions new];
    options.showFaqCategoriesAsGrid = self.gridval;
    options.showContactUsOnFaqScreens = self.switchVal;
    if(contactUsTagsArray.count){
        [options filterContactUsByTags:contactUsTagsArray withTitle:self.faqContactUsTitleField2.text];
    }
    [options filterByTags:arr withTitle:self.faqTitleField2.text andType: CATEGORY];
    [[Freshchat sharedInstance]showFAQs:self withOptions:options];
}

- (IBAction)sendMessage:(id)sender{
    NSString * tag =  [[self.sendMessageTag.text componentsSeparatedByString:@","] firstObject];
    FreshchatMessage *userMessage = [[FreshchatMessage alloc] initWithMessage:self.message.text andTag:tag];
    [[Freshchat sharedInstance] sendMessage:userMessage];
}

- (IBAction)switchAction:(id)sender {
    
    if ([self.mysWitch isOn]) {
        self.switchVal = true;
    } else {
        self.switchVal = false;
    }
}

- (IBAction)switchGridAction:(id)sender {
    
    if ([self.myGridSwitch isOn]) {
        self.gridval = true;
    } else {
        self.gridval = false;
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];// this will do the trick
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

@end
