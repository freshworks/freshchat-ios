//
//  HLMessagePoller.m
//  HotlineSDK
//
//  Created by Hrishikesh on 25/01/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLMessagePoller.h"
#import "KonotorDataManager.h"
#import "Message.h"
#import "HLConstants.h"
#import "HLMacros.h"
#import "FDUtilities.h"
#import "math.h"
#import "HLNotificationHandler.h"

#define MAX_POLL_INTERVAL_ON_SCREEN     5 // 1 minute;
#define MAX_POLL_INTERVAL_OFF_SCREEN    5 // 2 minutes;

@interface HLMessagePoller()

@property (nonatomic, strong) NSTimer *pollingTimer;
@property (nonatomic) enum MessageFetchType pollType ;
@property (nonatomic) NSTimeInterval interval;
@property (nonatomic) float backOff;
@property (nonatomic) BOOL ended;

@end

@implementation HLMessagePoller

-(instancetype) initWithPollType:(enum MessageFetchType) pollType{
    self = [super init];
    if(self){
        self.pollType = pollType;
    }
    return self;
}

-(void)logMsg:(NSString *) msg {
    FDLog(@"[%@][%f], %@" , self.pollType == OnscreenPollFetch ? @"OnScreen" : @"Background" , self.interval, msg );
}

-(void)begin{
    if(self.pollType == OnscreenPollFetch){
        self.interval = ON_CHAT_SCREEN_POLLER_INTERVAL * ([HLNotificationHandler areNotificationsEnabled]?2:1);
        self.backOff = 1.5;
    }
    if(self.pollType == OffScreenPollFetch){
        self.interval = OFF_CHAT_SCREEN_POLLER_INTERVAL;
        self.backOff = 1;
    }
    [self poll];
    [self logMsg:@"Polling started"];
}

-(void)poll{
    if(![self.pollingTimer isValid]){
        self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:self.interval target:self selector:@selector(pollMessages:)
                                                           userInfo:nil repeats:NO];
        self.ended = false;
    }
}

-(void)end{
    if([self.pollingTimer isValid]){
        [self.pollingTimer invalidate];
    }
    [self logMsg:@"Polling ended"];
    self.ended = true;
}

-(void)pollMessages:(NSTimer *)timer{
    NSManagedObjectContext *mainContext = [[KonotorDataManager sharedInstance] mainObjectContext];
    [mainContext performBlock:^{
        if([Message hasUserMessageInContext:mainContext]){
            if([Message daysSinceLastMessageInContext:mainContext] <= MAX_DAYS_SINCE_LAST_MESSAGE_FOR_POLL) {
                [self logMsg:[NSString stringWithFormat:@"Polling server now. Days since last Message %ld"
                              ,[Message daysSinceLastMessageInContext:mainContext]]];
                enum MessageRequestSource source = self.pollType == OnscreenPollFetch ?
                        ([HLNotificationHandler areNotificationsEnabled]?OnScreenPollWithToken:OnScreenPollWithoutToken)
                        :OffScreenPoll;
                [HLMessageServices fetchChannelsAndMessagesWithFetchType:self.pollType
                                                                  source:source
                                                              andHandler:^(NSError *error) {}];
            }
            else {
                [self logMsg:@"It has been long time since last message.not polling server"];
            }
        }
        else {
            [self logMsg:@"No user Messages. Skipping Fetch"];
        }
    }];
    [self setNext];
}

-(void)setNext {
    [self.pollingTimer invalidate]; // Not required since poller is not on repeat, but do it anyways
    self.interval =  fmin(self.interval * self.backOff,
                          self.pollType == OnscreenPollFetch ? MAX_POLL_INTERVAL_ON_SCREEN : MAX_POLL_INTERVAL_OFF_SCREEN);
    if(!self.ended){
        [self poll];
    }
}

-(void)reset {
    [self end];
    [self begin];
}

@end
