//
//  KonotorEventHandler.m
//  KonotorDemo
//
//  Created by Srikrishnan Ganesan on 20/08/13.
//  Copyright (c) 2013 Demach. All rights reserved.
//

#import "KonotorEventHandler.h"

static KonotorEventHandler* eventHandler=nil;

@implementation KonotorEventHandler
@synthesize badgeLabel;

-(void) didEncounterErrorWhileDownloadingConversations
{
//    [KonotorUtility showToastWithString:@"Updating conversations failed." forMessageID:nil];
    [KonotorUtility updateBadgeLabel:badgeLabel];
}

-(BOOL) handleRemoteNotification:(NSDictionary*)userInfo
{
    if(!([(NSString*)[userInfo valueForKey:@"source"] isEqualToString:@"konotor"]))
        return NO;
    
    [Konotor DownloadAllMessages];
    
    [KonotorUtility showToastWithString:@"New message received" forMessageID:@"all"];

    return YES;
}

-(BOOL) handleRemoteNotification:(NSDictionary*)userInfo withShowScreen:(BOOL)showScreen
{
    NSString* marketingId=((NSString*)[userInfo objectForKey:@"kon_message_marketingid"]);
    NSString* url=[userInfo valueForKey:@"kon_m_url"];
    if(showScreen&&marketingId&&([marketingId longLongValue]!=0))
        [Konotor MarkMarketingMessageAsClicked:[NSNumber numberWithLongLong:[marketingId longLongValue]]];
    
    if(showScreen&&(url!=nil)){
        @try{
            NSURL *clickUrl=[NSURL URLWithString:url];
            if([[UIApplication sharedApplication] canOpenURL:clickUrl]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] openURL:clickUrl];
                });
            }        }
        @catch(NSException *e){
            NSLog(@"%@",e);
        }
        
        [Konotor DownloadAllMessages];

        return YES;
    }
    else{
    
        if(!([(NSString*)[userInfo valueForKey:@"source"] isEqualToString:@"konotor"])){
            return NO;
        }
        
        [Konotor DownloadAllMessages];
        
        if(showScreen){
            [KonotorFeedbackScreen showFeedbackScreen];
        }
        else
            [KonotorUtility showToastWithString:@"New message received" forMessageID:@"all"];
        
        return YES;
    }
}

- (void) didFinishDownloadingMessages
{
    [KonotorUtility updateBadgeLabel:badgeLabel];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Konotor_FinishedMessagePull" object:nil];
}

- (void) didStartUploadingNewMessage{
}

+ (KonotorEventHandler*) sharedInstance
{
    if(eventHandler==nil)
        eventHandler=[[KonotorEventHandler alloc] init];
    return eventHandler;
}

@end
