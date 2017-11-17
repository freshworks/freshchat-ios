//
//  SampleController.m
//  Hotline Demo
//
//  Created by user on 14/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "SampleController.h"
#import "AppDelegate.h"
#import "FreshchatSDK/Freshchat.h"

@interface SampleController ()

@property (weak, nonatomic) IBOutlet UITextField *currentExternalID;
@property (weak, nonatomic) IBOutlet UITextField *currentRestoreID;
@property (weak, nonatomic) IBOutlet UITextField *nExternalID;
@property (weak, nonatomic) IBOutlet UITextField *nRestoreID;
@property (weak, nonatomic) IBOutlet UITextField *unreadCount;
@property (weak, nonatomic) IBOutlet UILabel *userDetails;

@end

@implementation SampleController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.currentRestoreID.text = [FreshchatUser sharedInstance].restoreID;
    self.currentExternalID.text = [FreshchatUser sharedInstance].externalID;
    [[NSNotificationCenter defaultCenter]addObserverForName:FRESHCHAT_USER_RESTORE_ID_GENERATED object:nil queue:nil usingBlock:^(NSNotification *note) {
        self.currentRestoreID.text = [FreshchatUser sharedInstance].restoreID;
        self.currentExternalID.text = [FreshchatUser sharedInstance].externalID;
        NSMutableString *userContent = [[NSMutableString alloc] initWithString:@""];
        if([FreshchatUser sharedInstance].firstName != nil) {
            userContent = [userContent stringByAppendingString: [FreshchatUser sharedInstance].firstName];
        }
        if([FreshchatUser sharedInstance].lastName != nil) {
            userContent = [userContent stringByAppendingString: [FreshchatUser sharedInstance].lastName];
        }
        if([FreshchatUser sharedInstance].email != nil) {
            userContent = [userContent stringByAppendingString: [FreshchatUser sharedInstance].email];
        }
        if([FreshchatUser sharedInstance].phoneCountryCode != nil) {
            userContent = [userContent stringByAppendingString: [FreshchatUser sharedInstance].phoneCountryCode];
        }
        if([FreshchatUser sharedInstance].phoneNumber != nil) {
            userContent = [userContent stringByAppendingString: [FreshchatUser sharedInstance].phoneNumber];
        }
        
        self.userDetails.text = userContent;
    }];
    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(handleSingleTap:)];
    [self.view addGestureRecognizer:singleFingerTap];
    [[NSNotificationCenter defaultCenter]addObserverForName:FRESHCHAT_UNREAD_MESSAGE_COUNT object:nil queue:nil usingBlock:^(NSNotification *note) {
        self.unreadCount.text = (note.userInfo[@"count"] != nil) ? [NSString stringWithFormat:@"%@ unread messages", note.userInfo[@"count"]] : @"0 unread messages";
        
        NSLog(@"Unread count  %@", note.userInfo[@"count"]);
    }];
    
}

-(void)viewDidUnload {
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter]removeObserver:FRESHCHAT_USER_RESTORE_ID_GENERATED];
    [[NSNotificationCenter defaultCenter]removeObserver:FRESHCHAT_UNREAD_MESSAGE_COUNT];
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    [self.view endEditing:YES];
}
- (IBAction)closeView:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loadChannels:(id)sender {
    [[Freshchat sharedInstance] showConversations:self];
}

- (IBAction)loadFAQs:(id)sender {
    [[Freshchat sharedInstance] showFAQs:self];
}

- (IBAction)clearUserData:(id)sender {
    FreshchatConfig *config = [[FreshchatConfig alloc]initWithAppID:[Freshchat sharedInstance].config.appID andAppKey:[Freshchat sharedInstance].config.appKey];
    config.domain = [Freshchat sharedInstance].config.domain;
    [[Freshchat sharedInstance]resetUserWithCompletion:^{        
        //[[Freshchat sharedInstance] setUser:[AppDelegate createFreshchatUser]];
    }];
}
- (IBAction)identifyUser:(id)sender {
    [[Freshchat sharedInstance] identifyUserWithExternalID:self.nExternalID.text restoreID:self.nRestoreID.text];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
