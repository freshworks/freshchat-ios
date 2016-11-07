//
//  FDControllerUtils.m
//  HotlineSDK
//
//  Created by user on 03/11/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FDControllerUtils.h"
#import "HLViewController.h"
#import "KonotorDataManager.h"
#import "HLContainerController.h"
#import "FDMessageController.h"
#import "HLChannelViewController.h"

@implementation FDControllerUtils

+(UIViewController *)getConvController:(BOOL)isEmbeded{
    UIViewController *controller;
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].mainObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_CHANNEL_ENTITY];
    request.predicate = [NSPredicate predicateWithFormat:@"isHidden == NO"];
    NSArray *results = [context executeFetchRequest:request error:nil];
    
    BOOL isModal = !isEmbeded;
    
    if (results.count == 1) {
        HLChannelInfo *channelInfo = [results firstObject];
        FDMessageController *msgController = [[FDMessageController alloc]initWithChannelID:channelInfo.channelID andPresentModally:isModal];
        controller = [[HLContainerController alloc]initWithController:msgController andEmbed:isEmbeded];
    }else{
        HLChannelViewController *channelController = [[HLChannelViewController alloc]init];
        controller = [[HLContainerController alloc]initWithController:channelController andEmbed:isEmbeded];
    }
    return controller;
}

@end
