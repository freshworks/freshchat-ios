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

@property (nonatomic, strong) IBOutlet UITextField *tagsField1;
@property (nonatomic, strong) IBOutlet UITextField *tagsField2;
@property (nonatomic, strong) IBOutlet UITextField *conatctUstags;
@property (nonatomic, strong) IBOutlet UITextField *messageField;
@property (nonatomic, strong) IBOutlet UITextField *filterTagsTitle;
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
    NSArray *arr = [self.tagsField1.text componentsSeparatedByString:@","];
    NSMutableArray *contactUsTagsArray =[[NSMutableArray alloc] initWithArray:[self.conatctUstags.text componentsSeparatedByString:@","]];
    [contactUsTagsArray removeObject:@""];
    FAQOptions *options = [FAQOptions new];
    options.showFaqCategoriesAsGrid = YES;
    options.showContactUsOnFaqScreens = self.switchVal;
    if(contactUsTagsArray.count){
        [options filterContactUsByTags:contactUsTagsArray withTitle:self.filterTagsTitle.text];
    }
    [options filterByTags:arr withTitle:self.filterTagsTitle.text andType: ARTICLE];
    [[Hotline sharedInstance]showFAQs:self withOptions:options];
}

- (IBAction)categoryFilter1:(id)sender{
    NSArray *arr = [self.tagsField1.text componentsSeparatedByString:@","];
    NSMutableArray *contactUsTagsArray =[[NSMutableArray alloc] initWithArray:[self.conatctUstags.text componentsSeparatedByString:@","]];
    [contactUsTagsArray removeObject:@""];
    FAQOptions *options = [FAQOptions new];
    options.showFaqCategoriesAsGrid = YES;
    options.showContactUsOnFaqScreens = self.switchVal;
    
    if(contactUsTagsArray.count){
        [options filterContactUsByTags:contactUsTagsArray withTitle:self.filterTagsTitle.text];
    }
    [options filterByTags:arr withTitle:self.filterTagsTitle.text andType: CATEGORY];
    [[Hotline sharedInstance]showFAQs:self withOptions:options];
}

- (IBAction)channelFilter1:(id)sender{
    
    NSArray *arr = [self.tagsField1.text componentsSeparatedByString:@","];
    ConversationOptions *opt = [ConversationOptions new];
    [opt filterByTags:arr withTitle:self.filterTagsTitle.text];
    [[Hotline sharedInstance] showConversations:self withOptions:opt];
}


//2
- (IBAction)articleFilter2:(id)sender{
    NSArray *arr = [self.tagsField2.text componentsSeparatedByString:@","];
    NSMutableArray *contactUsTagsArray =[[NSMutableArray alloc] initWithArray:[self.conatctUstags.text componentsSeparatedByString:@","]];
    [contactUsTagsArray removeObject:@""];
    FAQOptions *options = [FAQOptions new];
    options.showFaqCategoriesAsGrid = YES;
    options.showContactUsOnFaqScreens = self.switchVal;
    if(contactUsTagsArray.count){
        [options filterContactUsByTags:contactUsTagsArray withTitle:self.filterTagsTitle.text];
    }
    [options filterByTags:arr withTitle:self.filterTagsTitle.text andType: ARTICLE];
    [[Hotline sharedInstance]showFAQs:self withOptions:options];
}

- (IBAction)categoryFilter2:(id)sender{
    NSArray *arr = [self.tagsField2.text componentsSeparatedByString:@","];
    NSMutableArray *contactUsTagsArray =[[NSMutableArray alloc] initWithArray:[self.conatctUstags.text componentsSeparatedByString:@","]];
    [contactUsTagsArray removeObject:@""];
    FAQOptions *options = [FAQOptions new];
    options.showFaqCategoriesAsGrid = YES;
    options.showContactUsOnFaqScreens = self.switchVal;
    if(contactUsTagsArray.count){
        [options filterContactUsByTags:contactUsTagsArray withTitle:self.filterTagsTitle.text];
    }
    [options filterByTags:arr withTitle:self.filterTagsTitle.text andType: CATEGORY];
    [[Hotline sharedInstance]showFAQs:self withOptions:options];
}

- (IBAction)channelFilter2:(id)sender{
    NSArray *arr = [self.tagsField2.text componentsSeparatedByString:@","];
    ConversationOptions *opt = [ConversationOptions new];
    [opt filterByTags:arr withTitle:self.filterTagsTitle.text];
    [[Hotline sharedInstance] showConversations:self withOptions:opt];
}

- (IBAction)sendMessage:(id)sender{
    HotlineMessage *userMessage = [[HotlineMessage alloc] initWithMessage:self.messageField.text andTag:self.sendMessageTag.text];
    [[Hotline sharedInstance] sendMessage:userMessage];
}

- (IBAction)switchAction:(id)sender {
    
    if ([self.mysWitch isOn]) {
        self.switchVal = true;
    } else {
        self.switchVal = false;
    }
}

- (IBAction)contactFilter1:(id)sender{
    NSMutableArray *arr =[[NSMutableArray alloc] initWithArray:[self.conatctUstags.text componentsSeparatedByString:@","]];
    [arr removeObject:@""];
    
    FAQOptions *options = [FAQOptions new];
    options.showContactUsOnFaqScreens = YES;
    [options filterContactUsByTags:arr withTitle:self.filterTagsTitle.text];
    [options filterByTags:@[] withTitle:self.filterTagsTitle.text andType: CATEGORY];
    [[Hotline sharedInstance] showFAQs:self withOptions:options];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];// this will do the trick
}

@end
