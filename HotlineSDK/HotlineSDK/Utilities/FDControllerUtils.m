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

+(UIViewController *)getConvController:(BOOL)isEmbeded
                           withOptions:(ConversationOptions *)options
                           andChannels:(NSArray *)channels{
    UIViewController *controller;
    HLViewController *innerController;
    BOOL isModal = !isEmbeded;
    
    if (channels.count == 1) {
        HLChannelInfo *channelInfo = [channels firstObject];
        innerController = [[FDMessageController alloc]initWithChannelID:channelInfo.channelID andPresentModally:isModal];
    }else{
        innerController = [[HLChannelViewController alloc]init];
    }
    [HLConversationUtil setConversationOptions:options  andViewController:innerController];
    controller = [[HLContainerController alloc]initWithController:innerController andEmbed:isEmbeded];
    return controller;
}

@end
