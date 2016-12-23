//
//  ViewController.m
//  Hotline
//
//  Created by AravinthChandran on 9/7/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "ViewController.h"
#import "HotlineSDK/Hotline.h"
#import "FDSettingsController.h"
#import "AppDelegate.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *chatButton;
@property (nonatomic, strong) UIImageView *imageView;

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

@property (nonatomic, strong) IBOutlet UITextField *message;
@property (nonatomic, strong) IBOutlet UITextField *sendMessageTag;

@property (nonatomic, strong) IBOutlet UISwitch *mysWitch;

@property (nonatomic, assign) BOOL switchVal;

@end

@implementation ViewController

- (void)viewDidLoad {
    self.switchVal = true;
    [self setupSubview];
    
    self.view.backgroundColor = [UIColor colorWithHue:0 saturation:0 brightness:0.95 alpha:1];
    [super viewDidLoad];
}

-(void)setupSubview{
    self.imageView = [[UIImageView alloc]init];
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view insertSubview:self.imageView atIndex:0];
    
    NSDictionary *views = @{@"imgView" : self.imageView};
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imgView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imgView]|" options:0 metrics:nil views:views]];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.pickedImage) {
        self.imageView.image = appDelegate.pickedImage;
    }else{
        //self.imageView.image = [UIImage imageNamed:@"background"];
    }
}

- (IBAction)chatButtonPressed:(id)sender {
    [[Hotline sharedInstance] showFAQs:self];
}

- (IBAction)articleFilter1:(id)sender{
    NSArray *arr = [self.faqTagsField1.text componentsSeparatedByString:@","];
    NSMutableArray *contactUsTagsArray =[[NSMutableArray alloc] initWithArray:[self.faqContactUsTagsField1.text componentsSeparatedByString:@","]];
    [contactUsTagsArray removeObject:@""];
    FAQOptions *options = [FAQOptions new];
    options.showFaqCategoriesAsGrid = YES;
    options.showContactUsOnFaqScreens = self.switchVal;
    if(contactUsTagsArray.count){
        [options filterContactUsByTags:contactUsTagsArray withTitle:self.faqContactUsTitleField1.text];
    }
    [options filterByTags:arr withTitle:self.faqTitleField1.text andType: ARTICLE];
    [[Hotline sharedInstance]showFAQs:self withOptions:options];
}

- (IBAction)categoryFilter1:(id)sender{
    NSArray *arr = [self.faqTagsField1.text componentsSeparatedByString:@","];
    NSMutableArray *contactUsTagsArray =[[NSMutableArray alloc] initWithArray:[self.faqContactUsTagsField1.text componentsSeparatedByString:@","]];
    [contactUsTagsArray removeObject:@""];
    FAQOptions *options = [FAQOptions new];
    options.showFaqCategoriesAsGrid = YES;
    options.showContactUsOnFaqScreens = self.switchVal;
    if(contactUsTagsArray.count){
        [options filterContactUsByTags:contactUsTagsArray withTitle:self.faqContactUsTitleField1.text];
    }
    [options filterByTags:arr withTitle:self.faqTitleField1.text andType: CATEGORY];
    [[Hotline sharedInstance]showFAQs:self withOptions:options];
}



- (IBAction)channelFilter1:(id)sender{
    
    NSArray *arr = [self.conversationTags.text componentsSeparatedByString:@","];
    ConversationOptions *opt = [ConversationOptions new];
    [opt filterByTags:arr withTitle:self.conversationTitle.text];
    [[Hotline sharedInstance] showConversations:self withOptions:opt];
}


//2
- (IBAction)articleFilter2:(id)sender{
    NSArray *arr = [self.faqTagsField2.text componentsSeparatedByString:@","];
    NSMutableArray *contactUsTagsArray =[[NSMutableArray alloc] initWithArray:[self.faqContactUsTagsField2.text componentsSeparatedByString:@","]];
    [contactUsTagsArray removeObject:@""];
    FAQOptions *options = [FAQOptions new];
    options.showFaqCategoriesAsGrid = YES;
    options.showContactUsOnFaqScreens = self.switchVal;
    if(contactUsTagsArray.count){
        [options filterContactUsByTags:contactUsTagsArray withTitle:self.faqContactUsTitleField2.text];
    }
    [options filterByTags:arr withTitle:self.faqTitleField2.text andType: ARTICLE];
    [[Hotline sharedInstance]showFAQs:self withOptions:options];
}

- (IBAction)categoryFilter2:(id)sender{
    NSArray *arr = [self.faqTagsField2.text componentsSeparatedByString:@","];
    NSMutableArray *contactUsTagsArray =[[NSMutableArray alloc] initWithArray:[self.faqContactUsTagsField2.text componentsSeparatedByString:@","]];
    [contactUsTagsArray removeObject:@""];
    FAQOptions *options = [FAQOptions new];
    options.showFaqCategoriesAsGrid = YES;
    options.showContactUsOnFaqScreens = self.switchVal;
    if(contactUsTagsArray.count){
        [options filterContactUsByTags:contactUsTagsArray withTitle:self.faqContactUsTitleField2.text];
    }
    [options filterByTags:arr withTitle:self.faqTitleField2.text andType: CATEGORY];
    [[Hotline sharedInstance]showFAQs:self withOptions:options];
}

- (IBAction)sendMessage:(id)sender{
    HotlineMessage *userMessage = [[HotlineMessage alloc] initWithMessage:self.message.text andTag:self.sendMessageTag.text];
    [[Hotline sharedInstance] sendMessage:userMessage];
}

- (IBAction)switchAction:(id)sender {
    
    if ([self.mysWitch isOn]) {
        self.switchVal = true;
    } else {
        self.switchVal = false;
    }
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];// this will do the trick
}

@end
