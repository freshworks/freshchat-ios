//
//  FDSettingsController.m
//  Hotline
//
//  Created by Aravinth Chandran on 29/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDSettingsController.h"
#import "HotlineSDK/Hotline.h"

@interface FDSettingsController ()
@property (weak, nonatomic) IBOutlet UIScrollView *containerView;
@property (weak, nonatomic) IBOutlet UITextField *domainField;
@property (weak, nonatomic) IBOutlet UITextField *appIDField;
@property (weak, nonatomic) IBOutlet UITextField *appKeyField;
@property (weak, nonatomic) IBOutlet UITextField *userNameField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *phoneNumField;
@property (weak, nonatomic) IBOutlet UITextField *externalIDField;

@property (weak, nonatomic) IBOutlet UITextField *keyField;
@property (weak, nonatomic) IBOutlet UITextField *valueField;

@end

@implementation FDSettingsController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.containerView.contentSize = CGSizeMake(320, 750);
    [self updateFields];
}

- (IBAction)pushData:(id)sender {
    [[Hotline sharedInstance]setCustomUserPropertyForKey:self.keyField.text withValue:self.valueField.text];
}

- (IBAction)closeButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)clearDataPressed:(id)sender {
    [self updateFields];
    [[Hotline sharedInstance]clearUserData];
}

-(void)updateFields{
    self.domainField.text = [Hotline sharedInstance].config.domain;
    self.appIDField.text = [Hotline sharedInstance].config.appID;
    self.appKeyField.text = [Hotline sharedInstance].config.appKey;
    
    self.userNameField.text = [HotlineUser sharedInstance].userName;
    self.emailField.text = [HotlineUser sharedInstance].emailAddress;
    self.phoneNumField.text = [HotlineUser sharedInstance].phoneNumber;
    self.externalIDField.text = [HotlineUser sharedInstance].externalID;
}

@end