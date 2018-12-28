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
    self.listOfTokens.text = @"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwiZnJlc2hjaGF0X3V1aWQiOiJ0ZXN0aW5ndXNlcjIiLCJmaXJzdF9uYW1lIjoiVXNlciBCIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjE1NDE4MDU0Nzh9.PS4V4blWQS8YOYNoubZqLkKLn-YHjbsZff6yqd0SDhQkukRPR1RUOlrbhspQV4WLdYjwtOwprE7lhdqToqcsgEEXcQrlpXCKFat4CpxC-NGxrupmoC1AwFnl_3Psl8E9o_Ajj7581NaV0SUOoO0owsvKw0d-dBWm_uEra_6J2w2AN2Bm70Hd6XQGOHpyLeOn-Fxrpu4EuHJfO3Hqj8nSEQql0kR7wciAQ4HPHOj77jWsaE7Ufo7Haju97Q2Prb6ZsRoDrr9R9-YoMcRaVHE8hjReJekGUjKIT7ELzw9cE1D6MTna7W0idm5POZS-HuYbMpHnKSWF1xvN79YfOYgSFu8hWfnuh1t2s6HU18aZIESAjAKCgZcUCDiRLA7XVicP_vJEnZ9ZoMU2HTvHWpQfTzcuSQOZwlP9EdGlvGkb1_mg9CieKJT-zB35DBc6YX8VS2kp7rgXe03hdKVcufLcl4NGwli4zDHnyrk3ycd1fYDk0PI897YukuSBPOPn08PL8ASXBvDIMUL3UDYK6L-Akr8c_AQwmvTS4kIk8CF61-vp8_5YmB06v14_KzQ9hZa5gOYxMN4WOBNL6VldzMFC1djznCQ2YlwS5JRzptVs8gzTnZ6FEGcWyygp0AS3LETd5o9PK3DviUHR0YW50oLjoVDsdjnQqoU9hajcaTyF-8s";
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
