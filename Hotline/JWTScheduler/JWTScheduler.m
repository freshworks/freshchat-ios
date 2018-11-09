//
//  JWTScheduler.m
//  Hotline Demo
//
//  Created by Sanjith Kanagavel on 09/11/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JWTScheduler.h"
#import "FreshchatSDK/FreshchatSDK.h"

@interface JWTScheduler ()

@property (weak, nonatomic) IBOutlet UITextView *listOfTokens;
@property (weak, nonatomic) IBOutlet UITextView *currentToken;
@property (weak, nonatomic) IBOutlet UITextField *timerValue;
@property (weak, nonatomic) IBOutlet UIButton *startStopTimerBtn;
@property (weak, nonatomic) IBOutlet UILabel *currentTime;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sectionToggle;

@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic) int itemCount;
@property (nonatomic) int tickCount;

@end

@implementation JWTScheduler

- (void)viewDidLoad {
    [super viewDidLoad];
    [self getData];
    self.listOfTokens.text = @"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwiZnJlc2hjaGF0X3V1aWQiOiJ0ZXN0VXNlcjMiLCJyZWZlcmVuY2VfaWQiOiJ0ZXN0VXNlcjMiLCJmaXJzdF9uYW1lIjoiVXNlciAyIiwiaWF0IjoxNTQxNzQyNTgwfQ.Zxz3tQtxNbytgEdN44VBy8GaFgBvbwGL0aO-FOznt6-4RyJVaheDz5WVo4ukfmw3TAcEGDQHAsXCy_z2tP4ggRVr53lvImtWeQIMV95dfpQgkmma9djez07SzcC82MOaTMKC2eueL7p6k79C2a-0_3MIM0zgLh3nw2UDVYiTN89WqqXPQIimfsxxvESkTJXAK_RsvU75t_ylRCXYCKgbknlMsNfS0nAbFasK1wYC1yhIoEThz8CuG3uuRY458hpAkKZJPmHV09wVwUpmDJaCZ8jnpap1xYqNRinPq5mzyn9SO9w9V1wHrJpmPaaIFMVLFR9iPvwyAEScbZvZoYjf2iEX6wikK6-3TI_cw3qgPWjBcFTflpThzWP6sqh7x7a1li99FT99GBn3M_6ljXHl8Ty05BwhM-3id4t9FcbUpMUVZqHtwhiA8oFo2Q0ififlwtvLXWXcfcIQSGz0CKlx2N5dBBNChKBTR2s2f5fMHu9tbYmU347Koc-ugpyjV0kWw_W2qO5mtuxODf5lVrlEbrqeMleLv5SOXnEDRxSlzE9dAzp34V9Woa0KAAyZ9jii6cLYuUWS9GVysc4-a8JuUWV0tGBXgrnJHyXzKtkOIJGlCAOBrE_VJdso5QbH4rXsnhVkGln93XxzA5xaCUx-u30KnqKk4qo_2xd1UoHnHRY";
    [self.startStopTimerBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
}

- (IBAction)startStopTimer:(id)sender {
    if(self.timer == nil) {
        [self.startStopTimerBtn setTitle:@"Stop Timer" forState:UIControlStateNormal];
        [self.startStopTimerBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [self.timerValue setEnabled:FALSE];
        self.timerValue.alpha = 0.5;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(tokenSwapper) userInfo:nil repeats:YES];
    } else {
        [self.timer invalidate];
        self.timer = nil;
        self.tickCount = 0;
        [self.startStopTimerBtn setTitle:@"Start Timer" forState:UIControlStateNormal];
        [self.timerValue setEnabled:TRUE];
        self.timerValue.alpha = 1;
        self.currentTime.text = 0;
        [self.startStopTimerBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];

    }
}

-(void)tokenSwapper {
    if ( self.tickCount != 0 && self.tickCount % [self getTimeoutDuration] == 0) {
        NSArray *tokens = [self.listOfTokens.text componentsSeparatedByString:@","];
        self.itemCount = self.itemCount%[tokens count];
        NSString *tokenToProcess = tokens[self.itemCount];
        self.itemCount++;
        if ( tokenToProcess != nil ) {
            self.currentToken.text = tokenToProcess;
            if(self.sectionToggle.selectedSegmentIndex == 0) {
                [[Freshchat sharedInstance]setUserWithIdToken:tokenToProcess];
            } else {
                [[Freshchat sharedInstance]restoreUserWithIdToken:tokenToProcess];
            }
        }else {
            self.currentToken.text = @"<No-tokens>";
        }
        
        self.tickCount = 0;
    }
    self.currentTime.text =  [[NSString alloc] initWithFormat:@"%d",self.tickCount];
    self.tickCount ++;
}

-(int)getTimeoutDuration {
    if([self.timerValue.text isEqualToString:@""]) {
        return 10;
    } else {
        if([self.timerValue.text intValue] > 0) {
            return [self.timerValue.text intValue];
        } else {
            return 10;
        }
    }
}
- (IBAction)showConversations:(id)sender {
    [[Freshchat sharedInstance] showConversations:self];
}

- (IBAction)getTokenStatus:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"UserAlias" message:[[Freshchat sharedInstance] getUserIdTokenStatus]   preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)getUserAlias:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"UserAlias" message:[[Freshchat sharedInstance] getFreshchatUserId]   preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)dismissScreen:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (IBAction)saveTokens:(id)sender {
    NSString *listOfTokensArr = self.listOfTokens.text;
    [[NSUserDefaults standardUserDefaults] setObject:listOfTokensArr forKey:@"lotArr"];
}

-(void)getData {
    NSString *listOfTokensArr = [[NSUserDefaults standardUserDefaults] objectForKey:@"lotArr"];
    self.listOfTokens.text = @"<No-tokens>";
    self.currentToken.text = @"<No-tokens>";
    if (listOfTokensArr != nil) {
        self.listOfTokens.text = listOfTokensArr;
    }
}

@end
