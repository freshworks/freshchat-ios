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
    self.listOfTokens.text = @"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwiZnJlc2hjaGF0X3V1aWQiOiJUZXN0VXNlcjEiLCJyZWZlcmVuY2VfaWQiOiJUZXN0VXNlcjEiLCJmaXJzdF9uYW1lIjoiVGVzdFVzZXIiLCJsYXN0X25hbWUiOiIxIiwiaWF0IjoxNTQxNzQyNTgwfQ.clTcEtRGSSPrz3lHTOg7xTmm3jJyHAx-7c4Ug0U6YHaIjNLshyx7OdVtNrz6lc9LBoBuuSqyWqXgMe4RMXddQSaedLbhKb7byRoL8RaT75m9BL9CjJNCx76blbA6D2c__F7tt56R60mpA9wdnn9_ecUb7ndoA2-ndYFWYFwq-2NSC06lgPRfH4i9vQpLbF9BeKXgb1n-Y_JPowr5dX__O_U4cBooLTsa9n97m9T9zlIMZxyILYnZ8MZKxJh1ozqULKUtVHn7XDlusL6WHQZFDFf34ZqZKMxuAYwRL3vG9IHEQN2itRsRJUUEJU6aYTxuPdBJYmcF3S6judh1BXXTsbRRwvlC2YdQFaiQORt2m75kApMDAFqO73ChI36sa8mJn5jYS2QvnCgthUWYr7liiHLP7Kvm282ilABLoXz34E3triEyw6TjteSU8FyhZpFkTt_LoCxEKs80x7W9Qxlwocemeh4Aq1D_A_WzPe3_97CaT7HbwiPn_ghY32mnLPnWFULRfBvotJsHF40M1cfU5ZW99X-WVE-2CNqL0hov0aR0hG66Hs9HMkkY7t81guxsbkOtYkEphZ4ZYRLmwiiF3dK8azo0tEqmPF2RpjyhvwFolIx3SefVJB7gHhDsM4CPO89AamJcBVXHJeZ-wzEakcImuHwCrxdVFoWtSvtS5sg";
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
