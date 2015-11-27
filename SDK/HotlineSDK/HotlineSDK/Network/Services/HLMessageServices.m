//
//  HLMessageServices.m
//  HotlineSDK
//
//  Created by user on 03/11/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "HLMessageServices.h"
#import "HLAPIClient.h"
#import "HLServiceRequest.h"
#import "HLMacros.h"
#import "FDSecureStore.h"
#import "KonotorDataManager.h"
#import "HLChannel.h"
#import "HLAPI.h"
#import "FDLocalNotification.h"

@implementation HLMessageServices

-(NSURLSessionDataTask *)fetchAllChannels{
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:[NSURL URLWithString:HOTLINE_USER_DOMAIN]];
    request.HTTPMethod = HTTP_METHOD_GET;
    NSString *appID = @"4a10bd32-f0a5-4ac4-b95e-a88d405d0650";
    NSString *token = [NSString stringWithFormat:HOTLINE_REQUEST_PARAMS,@"3b649759-435e-4111-a504-c02335b9f999"];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_CHANNELS,appID];
    [request setRelativePath:path andURLParams:@[token]];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(id responseObject, NSError *error) {
        [self importChannels:responseObject];
        [[FDSecureStore sharedInstance] setObject:[NSDate date] forKey:HOTLINE_DEFAULTS_CHANNELS_LAST_UPDATED_TIME];
    }];
    return task;
}

-(void)importChannels:(NSDictionary *)responseObject{
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].mainObjectContext;
    [context performBlock:^{
        NSArray *channels = (NSArray *)responseObject;
        NSInteger channelCount = [channels count];
        HLChannel *channel = nil;
        if (channelCount!=0) {
            for(int i=0; i<channels.count; i++){
                NSDictionary *channelInfo = channels[i];
                channel = [HLChannel getWithID:channelInfo[@"channelId"] inContext:context];
                if (channel) {
                    NSDate *updateTime = [NSDate dateWithTimeIntervalSince1970:[channelInfo[@"updated"]doubleValue]];
                    if ([channel.lastUpdated compare:updateTime] == NSOrderedAscending) {
                        [HLChannel updateChannel:channel withInfo:channelInfo];
                        FDLog(@"Channel with ID:%@ updated", channelInfo[@"categoryId"]);
                    }
                }else{
                    channel = [HLChannel createWithInfo:channelInfo inContext:context];
                }
            }
        }
        [context save:nil];
        [self postNotification];
    }];
}

-(void)postNotification{
    [[NSNotificationCenter defaultCenter] postNotificationName:HOTLINE_CHANNELS_UPDATED object:self];
}

@end