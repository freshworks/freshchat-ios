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
#import "Hotline_Demo-Swift.h"

#define kOFFSET_FOR_KEYBOARD 160.0
#define SAMPLE_STORYBOARD_CONTROLLER @"SampleController"

@interface ViewController ()<UITextFieldDelegate,UITextViewDelegate,UIPickerViewDelegate,UIPickerViewDataSource,UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UIButton *chatButton;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) NSURL *soundUrl;
@property (weak, nonatomic) IBOutlet UILabel *unreadCountAll;
@property (weak, nonatomic) IBOutlet UILabel *unreadCountTags;

@property (nonatomic, strong) IBOutlet UITextField *faqTagsField1;

@property (nonatomic, strong) IBOutlet UITextView *jwtTextView;
@property (nonatomic, strong) IBOutlet UITextView *userAliasView;

@property (nonatomic, strong) IBOutlet UITextField *faqTitleField1;

@property (nonatomic, strong) IBOutlet UITextField *faqContactUsTagsField1;

@property (nonatomic, strong) IBOutlet UITextField *faqContactUsTitleField1;

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

@property (nonatomic, retain) UIAlertController *pickerViewPopup;
@property (nonatomic, retain) UIPickerView *categoryPickerView;
@property (nonatomic, retain) NSMutableArray *dataArray;
@property (weak, nonatomic) IBOutlet UIButton *languageTranslation;

@property (nonatomic, retain) IBOutlet UILabel *event;
@property (nonatomic, retain) IBOutlet UILabel *tokenState;

@end

@implementation ViewController

@synthesize pickerViewPopup,categoryPickerView;
@synthesize dataArray;

- (void)viewDidLoad {
    self.switchVal = true;
    self.gridval = true;
    [self setupSubview];
    [self.languageTranslation setHidden:YES];
    #if ENABLE_RTL_RUNTIME
        NSLog(@"You can change language on Runtime.");
        [self.languageTranslation setHidden:NO];
    #endif    
    self.view.backgroundColor = [UIColor colorWithHue:0 saturation:0 brightness:0.95 alpha:1];
    [super viewDidLoad];
    [self configurePicker];
    
    NSLog(@"~~Current User :Restore-ID  %@", [FreshchatUser sharedInstance].restoreID);
    NSLog(@"~~Current User :Identifier  %@", [FreshchatUser sharedInstance].externalID);
    
    [[Freshchat sharedInstance] unreadCountForTags:@[] withCompletion:^(NSInteger count) {
        self.unreadCountTags.text = [NSString stringWithFormat:@"UT  %d",count];
        NSLog(@"--With tags : %d",count);
    }];
    
    [[Freshchat sharedInstance] unreadCountWithCompletion:^(NSInteger count) {
        self.unreadCountAll.text = [NSString stringWithFormat:@"UC  %d",count];
        NSLog(@"--Without tags : %d",count);
    }];
    
    [[NSNotificationCenter defaultCenter]addObserverForName:FRESHCHAT_UNREAD_MESSAGE_COUNT_CHANGED object:nil queue:nil usingBlock:^(NSNotification *note) {
        [[Freshchat sharedInstance] unreadCountForTags:@[@"wow1",@"wow"] withCompletion:^(NSInteger count) {
            self.unreadCountTags.text = [NSString stringWithFormat:@"UT  %d",count];
            NSLog(@"--With tags : %d",count);
        }];
        
        [[Freshchat sharedInstance] unreadCountWithCompletion:^(NSInteger count) {
            self.unreadCountAll.text = [NSString stringWithFormat:@"UC  %d",count];
            NSLog(@"--Without tags : %d",count);
        }];
    }];
    
    self.faqTagsField1.delegate = self;
    self.faqTitleField1.delegate = self;
    self.faqContactUsTagsField1.delegate = self;
    self.faqContactUsTitleField1.delegate = self;
    self.conversationTitle.delegate = self;
    self.conversationTags.delegate = self;
    self.message.delegate = self;
    self.jwtTextView.delegate = self;
    self.userAliasView.delegate = self;
    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"jwtToken"];
    self.jwtTextView.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"jwtToken"];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(jwtActionEvent:)
                                                 name:FRESHCHAT_ACTION_USER_ACTIONS
                                               object:nil];
    
    
}

- (void) jwtActionEvent:(NSNotification *)notif {
    NSLog(@"====JWT Event - %@ ====", notif.userInfo[@"user_action"]);
    self.event.text = notif.userInfo[@"user_action"];
    NSLog(@"====JWT Event - %@ ====", [[Freshchat sharedInstance] getUserIdTokenStatus]);
    self.tokenState.text = [[Freshchat sharedInstance] getUserIdTokenStatus];
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

- (void)textViewDidChange:(UITextView *)textView {
    [[NSUserDefaults standardUserDefaults] setObject:self.jwtTextView.text forKey:@"jwtToken"];
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
    if ([sender isEqual:self.faqTitleField1]||[sender isEqual:self.faqTagsField1]||[sender isEqual:self.faqContactUsTagsField1]||[sender isEqual:self.faqContactUsTitleField1])
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
    [self updateSelectedItem];
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
    UIViewController *viewController = [[Freshchat sharedInstance] getConversationsControllerForEmbedWithOptions:opt];
    [self.navigationController pushViewController:viewController animated:true];
    
    
    //
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

- (IBAction)showLanguagePicker:(id)sender {
    [self presentViewController:self.pickerViewPopup animated:true completion:nil];
}



//2
- (IBAction)setJWTUser:(id)sender{
//    if(self.jwtTextView.text.length == 0){
//        return;
//    }
    [[Freshchat sharedInstance] setUserWithIdToken:@"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwiZmlyc3RfbmFtZSI6IlRlc3RpbmdkYWQiLCJmcmVzaGNoYXRfdXVpZCI6ImcyNCIsInJlZmVyZW5jZV9pZCI6InRlc3RoZ2FoamRhc2hqZGEiLCJpYXQiOjE1MTYyMzkwMjIsImV4cCI6MTUxNjIzOTAyM30.Vc-TuNkpvUs7FEzi2Lphzm-AHLynuK6D-N_R3kDdXbx7ReBMtDDOjsPjcp4BWKQOKRLUD_phDA7_dQAnQWG7HKAb4YtGf6VOcwg53tDWnwj85srZsXUj83rAyG7fG36O7qXu6s3el6S8yfLgHdX9ybO3btjxSyfUcPkKQfz8g2YMWZLUapdUik-K20xr6e0TcRkP34D-4sXiMxH4JsPzevXXs3eRC0ZQFcDjr-j0s8AaUdsX05ECgyPMH0TBvHiWAQFA_vaYiEJdS4NlbvQP9srUtmtjJbPgyukthwbayXnXgxjKOYje5yanjOvimsavkrOkhutycKAVNmLt5WaR4VSBcegpHBXh676Y23Qf_S1vx56BpJ7TS5BteDl8Mkjxe_dW3mGzcNyZeRSR9WDVqLUFV-6CxsMM76e8G8hLKFc9JnA488KSyfzKdaqzo621bkt8pteNHEFXA2cMSY6NzTcTfcLwk36D-EAQUWFZ5G5fSb1gCWdh-U10d2tMxXy6d-WUi2R3vomg-XGAjlAsSEhHw57qbeK7XW_To3axzuZ6msvBCpciRnLm8KPgWKIkG7rDq7KQpw7tv0XbMtBk0pjzueeiXpu3ZgT4dl7z-bBpOnaBgSL3LJYFF0oB7iwvs8C1VzWARyDjWEDiIEpe79okOcwtiyBN-TTQr4nPMWM"];
}

- (IBAction)idenfiyJWTUser:(id)sender{
    [[Freshchat sharedInstance] restoreUserWithIdToken:@"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwiZmlyc3RfbmFtZSI6IlRlc3RpbmdkYWQiLCJmcmVzaGNoYXRfdXVpZCI6ImcyNCIsInJlZmVyZW5jZV9pZCI6InRlc3RoZ2FoamRhc2hqZGEiLCJpYXQiOjE1MTYyMzkwMjJ9.PO0gN4j-CARmEKQaG-IZG_VgyVtZq4K8dSikWnSiE0Vdhqm_Gp1yUfy_xM5N3qyzXVktgmSufF66Yf0QVaChuS8gKPuQYWacLuT5WqZht5jI2UZ9yJcBU_NK0W8bq7t3gdtmSnFoL-mET7Cc5ReX-VRcxIzojJhrbHU5V9YEcoauzOmqNo0Bii0ClcDc7L2cUXLvCTDdt-UZOrz35iYf4vDFJ1gVX6d-DReV6QK_dt1pvxP5jRBGzEoXHGMZYn7mkylsq_0IZtd0OmZ-XE3N8ZY35GbHrskMzs--7CtuLEnv04H93Yv9ct2zdaK2TF5gPJl8EJobuIjaNxa5RTihxiTNvCTeqTU8kpMwJFg_DSXPj-MJ_ePOgR_necpe_jb5pggflM6DjERFbhm7L7pFgsZjplNDxqkvQyUJGs1d3JrfCPA1Kpn4W2wbpU-GJkAP_50E8NE32ksiZuQQxyCk-Z92SQYjTocDH_q_t5vze9pxO9rOGIqOj7llOqBxiWNbuFOvnQ5wen6eS-ZgYK1-_2qFrmzfYM9p-wzazcZkfGwoj0ZXFa-5wp7X-THMmxqOpbq14gjTZbXTRJC3w0Y8fK8JUeCmVtfMkHg24jFl31PJRNtd9Fb9B80TWeOSvr4YF6xkYfEC3wF3jJx65LPSg-S7sH76ayV3ASnniBR2j5Q"];
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

- (IBAction) getUserAliasForJWT:(id)sender {
    self.userAliasView.text = [[Freshchat sharedInstance] getFreshchatUserId];
    NSLog(@"User Id is - %@", [[Freshchat sharedInstance] getFreshchatUserId]);
    NSLog(@"User Token state - %@",[[Freshchat sharedInstance] getUserIdTokenStatus]);
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

-(void) configurePicker  {
    self.dataArray = [[NSMutableArray alloc] initWithArray:@[@"en", @"ar", @"fr"]];
    self.pickerViewPopup = [UIAlertController alertControllerWithTitle:@"\n\n\n\n\n\n" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    self.categoryPickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, pickerViewPopup.view.bounds.size.width,150)];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
    [self.pickerViewPopup addAction:cancelAction];
    [self.categoryPickerView setDataSource:self];
    [self.categoryPickerView setDelegate:self];
    self.categoryPickerView.showsSelectionIndicator = YES;
    UIToolbar *pickerToolbar = [[UIToolbar alloc] init];
    pickerToolbar.barStyle = UIBarStyleBlackOpaque;
    [pickerToolbar sizeToFit];
    
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(categoryDoneButtonPressed)];
    
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(categoryCancelButtonPressed)];
    
    [pickerToolbar setItems:@[cancelBtn, flexSpace, doneBtn] animated:YES];
    
    //[self.pickerViewPopup.view addSubview:pickerToolbar];
    [self.pickerViewPopup.view addSubview:self.categoryPickerView];
    [self.pickerViewPopup.view setBounds:CGRectMake(0,0,320, 464)];
}

-(void) updateSelectedItem {
    NSInteger selectedIndex = [dataArray indexOfObject:[L102Language currentAppleLanguage]];
    if(selectedIndex >= 0) {
        [self.categoryPickerView selectRow:selectedIndex inComponent:0 animated:true];
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow: (NSInteger)row inComponent:(NSInteger)component {
    NSString *selectedCategory = [NSString stringWithFormat:@"%@",[dataArray objectAtIndex:row]];
    [L102Language setAppleLAnguageToLang:selectedCategory];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if([selectedCategory isEqualToString:@"ar"]) {
        UIView.appearance.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    } else {
        UIView.appearance.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
    }
    [appDelegate setupRootController];
    __weak typeof(self)weakSelf = self;
    [[NSNotificationCenter defaultCenter] postNotificationName:FRESHCHAT_USER_LOCALE_CHANGED object:weakSelf];
    [self updateSelectedItem];
}
// tell the picker how many rows are available for a given component
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [dataArray count];
}

// tell the picker how many components it will have
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// tell the picker the title for a given component
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [dataArray objectAtIndex: row];
    
}

// tell the picker the width of each row for a given component
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    int sectionWidth = 300;
    return sectionWidth;
}

@end
