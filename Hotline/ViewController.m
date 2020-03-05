//
//  ViewController.m
//  Hotline
//
//  Created by AravinthChandran on 9/7/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FreshchatSDK/FreshchatSDK.h"
#import "FDSettingsController.h"
#import "AppDelegate.h"
#import "ViewController.h"
#import "InAppBrowser.h"
#import "SampleController.h"
#import "JWTScheduler.h"
#import "Hotline_Demo-Swift.h"

#define kOFFSET_FOR_KEYBOARD 160.0
#define SAMPLE_STORYBOARD_CONTROLLER @"SampleController"
#define JWT_SCHEDULER_STORYBOARD_CONTROLLER @"JWTScheduler"
#define JWT_TEST_SAMPLE_STORYBOARD_CONTROLLER @"JWTTestViewController"

@interface ViewController ()<UITextFieldDelegate,UITextViewDelegate,UIPickerViewDelegate,UIPickerViewDataSource,UIActionSheetDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *chatButton;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) NSURL *soundUrl;
@property (weak, nonatomic) IBOutlet UILabel *unreadCountAll;
@property (weak, nonatomic) IBOutlet UILabel *unreadCountTags;

@property (nonatomic, strong) IBOutlet UITextField *faqTagsField1;

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
@property (nonatomic, strong) IBOutlet UISwitch *faqNotHelpfulSwitch;
@property (nonatomic, strong) IBOutlet UISwitch *showContactUsOnAppBarSwitch;

@property (nonatomic, assign) BOOL switchVal;
@property (nonatomic, assign) BOOL gridFaqVal;
@property (nonatomic, assign) BOOL faqHelpfulVal;
@property (nonatomic, assign) BOOL contactUsAppbarVal;

@property (nonatomic, retain) UIAlertController *pickerViewPopup;
@property (nonatomic, retain) UIPickerView *categoryPickerView;
@property (nonatomic, retain) NSMutableArray *dataArray;
@property (weak, nonatomic) IBOutlet UIButton *languageTranslation;

@property (nonatomic, retain) IBOutlet UILabel *event;
@property (weak, nonatomic) IBOutlet UILabel *restoreIDCount;

@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) UITextField *activeField;

@property (nonatomic, strong) JWTTestViewController *jwtTestViewController;

@property (nonatomic, strong)InEventsController *inbountTrackVC;

@property int restoreEventCount;

@end

@implementation ViewController

@synthesize pickerViewPopup,categoryPickerView;
@synthesize dataArray;

- (void)viewDidLoad {
    NSString *str = [[NSUserDefaults standardUserDefaults] stringForKey:@"hybridExperience.url"];
    self.faqTagsField1.text = str;
    self.switchVal = true;
    self.gridFaqVal = true;
    self.faqHelpfulVal = true;
    self.contactUsAppbarVal = true;
    
    [self setupSubview];
    [self.languageTranslation setHidden:YES];
    #if ENABLE_RTL_RUNTIME
        NSLog(@"You can change language on Runtime.");
        [self.languageTranslation setHidden:NO];
    #endif    
    self.view.backgroundColor = [UIColor colorWithHue:0 saturation:0 brightness:0.95 alpha:1];
    [super viewDidLoad];
    [self configurePicker];
    
    self.scrollView.delegate = self;
    
    NSLog(@"~~Current User :Restore-ID  %@", [FreshchatUser sharedInstance].restoreID);
    NSLog(@"~~Current User :Identifier  %@", [FreshchatUser sharedInstance].externalID);
    
    [[Freshchat sharedInstance] unreadCountForTags:@[] withCompletion:^(NSInteger count) {
        self.unreadCountTags.text = [NSString stringWithFormat:@"UT  %d",count];
        NSLog(@"--With tags : %d",count);
    }];
    
    [Freshchat sharedInstance].customLinkHandler = ^BOOL(NSURL * url) {
        UIStoryboard *inAppBrowserSB = [UIStoryboard storyboardWithName:IN_APP_BROWSER_STORYBOARD_CONTROLLER bundle:nil];
        InAppBrowser *inAppBrowserVC = [inAppBrowserSB instantiateViewControllerWithIdentifier:IN_APP_BROWSER_STORYBOARD_CONTROLLER];
        inAppBrowserVC.url = url;
        UIViewController *topController = [self.navigationController visibleViewController];
        [topController presentViewController:inAppBrowserVC animated:YES completion:nil];
        NSLog(@"%@",url.description);
        return YES;
    };
    
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
    [[NSNotificationCenter defaultCenter]addObserverForName:FRESHCHAT_USER_RESTORE_ID_GENERATED object:nil queue:nil usingBlock:^(NSNotification *note) {
        self.restoreEventCount = self.restoreEventCount + 1;
        self.restoreIDCount.text = [NSString stringWithFormat:@"RE Count : %d",self.restoreEventCount];
     }];

    
    self.faqTagsField1.delegate = self;
    self.faqTitleField1.delegate = self;
    self.faqContactUsTagsField1.delegate = self;
    self.faqContactUsTitleField1.delegate = self;
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userActionEvent:)
                                                 name:FRESHCHAT_EVENTS
                                               object:nil];
    [self registerForKeyboardNotifications];
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
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;

    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your application might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, self.activeField.frame.origin) ) {
        CGPoint scrollPoint = CGPointMake(0.0, self.activeField.frame.origin.y-kbSize.height);
        [self.scrollView setContentOffset:scrollPoint animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.activeField = nil;
}

- (void) userActionEvent:(NSNotification *)notif {
    
    FreshchatEvent *fcEvent = notif.userInfo[@"event"];
    
    NSLog(@"====Freshchat event  - %@ ====", [fcEvent getEventName]);
    self.event.text = [fcEvent getEventName];
    
    //Compare with any event name
    if(fcEvent.name == FCEventFAQOpen){
        NSLog(@"Category open event");
    }
    
    //Print event properties
    NSLog(@"Event properties %@", fcEvent.properties);
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
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
}
JWTScheduler *jwtScheduler;

- (IBAction)chatButtonPressed:(id)sender {
     SampleController *sampleController;

     //SampleViewController hidden
     if(sampleController == nil) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:SAMPLE_STORYBOARD_CONTROLLER bundle:nil];
        sampleController = [sb instantiateViewControllerWithIdentifier:SAMPLE_STORYBOARD_CONTROLLER];
    }
    [self presentViewController:sampleController animated:YES completion:nil];
     
    /*
    
    if( jwtScheduler == nil) {
        UIStoryboard *jwtSchedulerSB = [UIStoryboard storyboardWithName:JWT_SCHEDULER_STORYBOARD_CONTROLLER bundle:nil];
        jwtScheduler = [jwtSchedulerSB instantiateViewControllerWithIdentifier:JWT_SCHEDULER_STORYBOARD_CONTROLLER];
    }
    [self presentViewController:jwtScheduler animated:YES completion:nil];
     */
}

- (IBAction) loadJWTTestSampleView:(id)sender{
    
    UIStoryboard *jwtSampleView = [UIStoryboard storyboardWithName:JWT_TEST_SAMPLE_STORYBOARD_CONTROLLER bundle:nil];
    self.jwtTestViewController = [jwtSampleView instantiateViewControllerWithIdentifier:JWT_TEST_SAMPLE_STORYBOARD_CONTROLLER];
    self.jwtTestViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:self.jwtTestViewController animated:YES completion:nil];
}

- (IBAction)articleFilter1:(id)sender{
    NSArray *arr = [self.faqTagsField1.text componentsSeparatedByString:@","];
    NSMutableArray *contactUsTagsArray =[[NSMutableArray alloc] initWithArray:[self.faqContactUsTagsField1.text componentsSeparatedByString:@","]];
    [contactUsTagsArray removeObject:@""];
    FAQOptions *options = [FAQOptions new];
    options.showFaqCategoriesAsGrid = self.gridFaqVal;
    options.showContactUsOnFaqScreens = self.switchVal;
    options.showContactUsOnFaqNotHelpful = self.faqHelpfulVal;
    options.showContactUsOnAppBar = self.contactUsAppbarVal;
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
    options.showFaqCategoriesAsGrid = self.gridFaqVal;
    options.showContactUsOnFaqScreens = self.switchVal;
    options.showContactUsOnFaqNotHelpful = self.faqHelpfulVal;
    options.showContactUsOnAppBar = self.contactUsAppbarVal;
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
    [[Freshchat sharedInstance] showConversations:self];
   
}
- (IBAction)urlChange:(id)sender {
    NSString *valueToSave = self.faqTagsField1.text;
    [[NSUserDefaults standardUserDefaults] setObject:valueToSave forKey:@"hybridExperience.url"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)showLanguagePicker:(id)sender {
    [self presentViewController:self.pickerViewPopup animated:true completion:nil];
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
        self.gridFaqVal = true;
    } else {
        self.gridFaqVal = false;
    }
}

- (IBAction)switchAppBarAction:(id)sender {
    
    if ([self.showContactUsOnAppBarSwitch isOn]) {
        self.contactUsAppbarVal = true;
    } else {
        self.contactUsAppbarVal = false;
    }
}

- (IBAction)switchFAQHelpfulAction:(id)sender {
    
    if ([self.faqNotHelpfulSwitch isOn]) {
        self.faqHelpfulVal = true;
    } else {
        self.faqHelpfulVal = false;
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

- (IBAction)launchEventsView:(id) sender {
    
    UIStoryboard* storyboard = [UIStoryboard
                               storyboardWithName:EVENTS_TRACK_VIEW_STORYBOARD_CONTROLLER
                                                         bundle:nil];
    InEventsController *inEventCtr = [storyboard instantiateViewControllerWithIdentifier:@"inEvents"];
    inEventCtr.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:inEventCtr
                       animated:YES
                     completion:nil];
}

@end
