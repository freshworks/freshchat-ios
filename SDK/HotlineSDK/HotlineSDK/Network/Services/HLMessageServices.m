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
#import "HLAPI.h"
#import "FDLocalNotification.h"

@implementation HLMessageServices

-(NSURLSessionDataTask *)fetchAllChannels:(void (^)(NSArray<HLChannel *> *channels, NSError *error))handler{
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    FDSecureStore *store = [FDSecureStore sharedInstance];
    //TODO: This is repeated multitimes. Needs refactor.
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:HOTLINE_USER_DOMAIN,[store objectForKey:HOTLINE_DEFAULTS_DOMAIN]]]];
    request.HTTPMethod = HTTP_METHOD_GET;
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *appKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_CHANNELS_PATH,appID];
    NSString *token = [NSString stringWithFormat:HOTLINE_REQUEST_PARAMS,appKey];
    [request setRelativePath:path andURLParams:@[token]];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(id responseObject, NSError *error) {
        if (!error) {
            [self importChannels:responseObject hanlder:handler];
        }else{
            if (handler) handler(nil, error);
        }
    }];
    return task;
}

-(void)importChannels:(NSDictionary *)responseObject hanlder:(void (^)(NSArray *channels, NSError *error))handler;{
    NSMutableArray *channelList = [NSMutableArray new];
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
                [channelList addObject:channel];
            }
        }
        [context save:nil];
        if (handler) handler(channelList,nil);
        [self postNotification];
    }];
}

-(void)postNotification{
    [[NSNotificationCenter defaultCenter] postNotificationName:HOTLINE_CHANNELS_UPDATED object:self];
}

@end