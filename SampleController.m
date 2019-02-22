//
//  SampleController.m
//  Hotline Demo
//
//  Created by user on 14/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "SampleController.h"
#import "AppDelegate.h"
#import "FreshchatSDK/FreshchatSDK.h"

@interface SampleController ()

@property (weak, nonatomic) IBOutlet UITextField *currentExternalID;
@property (weak, nonatomic) IBOutlet UITextField *currentRestoreID;
@property (weak, nonatomic) IBOutlet UITextField *nExternalID;
@property (weak, nonatomic) IBOutlet UITextField *nRestoreID;
@property (weak, nonatomic) IBOutlet UITextField *unreadCount;
@property (weak, nonatomic) IBOutlet UILabel *userDetails;
@property (weak, nonatomic) IBOutlet UISwitch *timerState;
@property (weak, nonatomic) IBOutlet UITextField *timeoutDuration;
@property (weak, nonatomic) IBOutlet UISegmentedControl *value;
@property (weak, nonatomic) IBOutlet UISwitch *state;
@property (nonatomic) BOOL kill;
@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic) int itemCount;
@property (weak, nonatomic) IBOutlet UISwitch *restoreEventSwitch;


@end

@implementation SampleController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.kill = true;
    self.itemCount = 0;
    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(handleSingleTap:)];
    [self.view addGestureRecognizer:singleFingerTap];
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
    

}

-(float)getTimeoutDuration {
    if([self.timeoutDuration.text isEqualToString:@""]) {
        return 10.0f;
    } else {
        if([self.timeoutDuration.text floatValue] > 0) {
            return [self.timeoutDuration.text floatValue];
        } else {
           return 10.0f;
        }
    }
}

-(void)getData {
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"nRestoreID"] != nil && [[NSUserDefaults standardUserDefaults] objectForKey:@"nRestoreID"] != nil ) {
        self.nRestoreID.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"nRestoreID"];
        self.nExternalID.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"nExternalID"];
    } else {
        self.nRestoreID.text = @"a53df44e-6023-4402-8c08-549fd70628f3";
        self.nExternalID.text = @"test";
    }
}

- (IBAction)saveData:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:self.nRestoreID.text forKey:@"nRestoreID"];
    [[NSUserDefaults standardUserDefaults] setObject:self.nExternalID.text forKey:@"nExternalID"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)timerState:(id)sender {
    if(self.timerState.isOn) {
        if(self.timer.isValid) {
            [self.timer invalidate];
        }
        self.timer = [NSTimer scheduledTimerWithTimeInterval:[self getTimeoutDuration] target:self selector:@selector(accountSwapper) userInfo:nil repeats:YES];
    } else {
        [self.timer invalidate];
    }
}

- (IBAction)valueChanged:(id)sender {
    self.kill = self.value.selectedSegmentIndex == 0 ? true : false;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.currentRestoreID.text = [FreshchatUser sharedInstance].restoreID;
    self.currentExternalID.text = [FreshchatUser sharedInstance].externalID;
    [self getData];
}

-(void)accountSwapper {
    NSArray *externalIds = [self.nExternalID.text componentsSeparatedByString:@","];
    NSArray *restoreIds = [self.nRestoreID.text componentsSeparatedByString:@","];
    //int random = rand() % externalIds.count;
    self.itemCount = self.itemCount%[restoreIds count];
    int random = self.itemCount;
    NSString *externalID = externalIds[random];
    NSString *restorelID = restoreIds[random];
    self.itemCount++;
    if([externalID isEqualToString:@"clear"] || [restorelID isEqualToString:@"clear"] ) {
        [[Freshchat sharedInstance] resetUserWithCompletion:nil];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Dhoom damaka" message:@"Trashing and rebooting SDK." delegate:self cancelButtonTitle:@"Blaah" otherButtonTitles:nil];
        //[alert show];
    } else if(externalID == nil || restorelID == nil) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Dummel" message:[NSString stringWithFormat:@"Dude. Give correct count index and values",externalID,restorelID] delegate:self cancelButtonTitle:@"Blaah" otherButtonTitles:nil];
        //[alert show];
    } else {
        [[Freshchat sharedInstance] identifyUserWithExternalID:externalID restoreID:restorelID];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Dhoom damaka" message:[NSString stringWithFormat:@"Account Switched - %@ - %@",externalID,restorelID] delegate:self cancelButtonTitle:@"Blaah" otherButtonTitles:nil];
        //[alert show];
    }
    NSLog(@"ExternalId-RestoreId: %@ -- %@",externalID,restorelID);
}

-(void)viewDidUnload {
    [super viewDidUnload];
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    [self.view endEditing:YES];
}

- (IBAction)closeView:(id)sender {
    if(self.kill) {
        [self.timer invalidate];
        [self.timerState setOn:false];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FRESHCHAT_USER_RESTORE_ID_GENERATED object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:FRESHCHAT_UNREAD_MESSAGE_COUNT_CHANGED];
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loadChannels:(id)sender {
    ConversationOptions *opt = [ConversationOptions new];
    [opt filterByTags:@[@"wow"] withTitle:@"heyyyy"];
    //[[Freshchat sharedInstance] openFreshchatDeeplink:@"freshchat://channels?id=192" viewController:self];

    //[[Freshchat sharedInstance] showConversations:self withOptions:opt];
    [[Freshchat sharedInstance] showConversations:self];
}

- (IBAction)loadFAQs:(id)sender {
    [[Freshchat sharedInstance] showFAQs:self];
    //[[Freshchat sharedInstance] openFreshchatDeeplink:@"freshchat://channels1?id=192" viewController:self];

}

- (IBAction)restoreEvent:(id)sender {
    if(self.restoreEventSwitch.isOn) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createLoopInRestoreID) name:FRESHCHAT_USER_RESTORE_ID_GENERATED object:nil];
        [[Freshchat sharedInstance] identifyUserWithExternalID:@"sanjith" restoreID:@"d6cdc47a-8028-42d6-9d84-cd2a08fdd1a8"];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:FRESHCHAT_USER_RESTORE_ID_GENERATED object:nil];
    }
}

-(void) createLoopInRestoreID {
    NSLog(@"Loop:::");
    for (int i=0; i<=3; i++) {
        FreshchatUser *user = [FreshchatUser sharedInstance];
        user.firstName = @"Hey";
        user.lastName = @"There";
        user.email = @"adsfasfasfads@asdfsd.com";
        [[Freshchat sharedInstance] setUser:user];
        
        [[Freshchat sharedInstance] setUserProperties:@{ @"SDK Version" : [Freshchat SDKVersion] }];
        
        FreshchatMessage *message = [[FreshchatMessage alloc] init];
        [message setMessage:@"Hey there"];
    }
}

- (IBAction)clearUserData:(id)sender {
    FreshchatConfig *config = [[FreshchatConfig alloc]initWithAppID:[Freshchat sharedInstance].config.appID andAppKey:[Freshchat sharedInstance].config.appKey];
    config.domain = [Freshchat sharedInstance].config.domain;
    [[Freshchat sharedInstance]resetUserWithCompletion:^{        
        //[[Freshchat sharedInstance] setUser:[AppDelegate createFreshchatUser]];
    }];
}
- (IBAction)identifyUser:(id)sender {
    [self accountSwapper];
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
