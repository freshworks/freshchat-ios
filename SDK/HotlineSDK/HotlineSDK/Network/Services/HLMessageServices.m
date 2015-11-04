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
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:[NSURL URLWithString:HOTLINE_API_CHANNELS]];
    request.HTTPMethod = HTTP_METHOD_GET;
    request.URL = [NSURL URLWithString:HOTLINE_API_CHANNELS];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(id responseObject, NSError *error) {
        [self importChannels:responseObject];
        [[FDSecureStore sharedInstance] setObject:[NSDate date] forKey:HOTLINE_DEFAULTS_CHANNELS_LAST_UPDATED_TIME];
    }];
    return task;
}

-(void)importChannels:(NSDictionary *)responseObject{
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].backgroundContext;
    [context performBlock:^{
        NSArray *channels = (NSArray *)responseObject;
        HLChannel *channel = nil;
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
        [context save:nil];
        [self postNotification];
    }];
}

-(void)postNotification{
    [[NSNotificationCenter defaultCenter] postNotificationName:HOTLINE_CHANNELS_UPDATED object:self];
}

@end
