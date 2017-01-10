//
//  HLControllerUtils.m
//  HotlineSDK
//
//  Created by user on 03/11/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "HLControllerUtils.h"
#import "HLViewController.h"
#import "KonotorDataManager.h"
#import "HLContainerController.h"
#import "FDMessageController.h"
#import "HLChannelViewController.h"
#import "FDBarButtonItem.h"
#import "HLLocalization.h"

@implementation HLControllerUtils

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

+(void) configureBackButtonForController:(UIViewController *) controller
                            withEmbedded:(BOOL) isEmbedded{
    BOOL isBackButtonImageExist = [[HLTheme sharedInstance]getImageWithKey:IMAGE_BACK_BUTTON] ? YES : NO;
    if (isBackButtonImageExist && !isEmbedded) {
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[[HLTheme sharedInstance] getImageWithKey:IMAGE_BACK_BUTTON]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:controller.navigationController
                                                                      action:@selector(popViewControllerAnimated:)];
        controller.parentViewController.navigationItem.leftBarButtonItem = backButton;
    }else{
        controller.parentViewController.navigationItem.backBarButtonItem = [[FDBarButtonItem alloc] initWithTitle:@""
                                                                                                            style:controller.parentViewController.navigationItem.backBarButtonItem.style
                                                                                                           target:nil action:nil];
    }
}

+(void) configureCloseButton:(UIViewController *) controller
                   forTarget:(id)targetObj
                    selector: (SEL) actionSelector {
    UIBarButtonItem *closeButton = [[FDBarButtonItem alloc]initWithTitle:HLLocalizedString(LOC_FAQ_CLOSE_BUTTON_TEXT)
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:targetObj
                                                                  action:actionSelector];
    if(!controller.parentViewController.navigationItem.leftBarButtonItem ) {
        controller.parentViewController.navigationItem.leftBarButtonItem = closeButton;
    }
}

+(void) configureGestureDelegate:(UIViewController <UIGestureRecognizerDelegate> *)gestureDelegate
                   forController:(UIViewController *) controller
                    withEmbedded:(BOOL) isEmbedded{
    
    BOOL isBackButtonImageExist = [[HLTheme sharedInstance]getImageWithKey:IMAGE_BACK_BUTTON] ? YES : NO;
    UINavigationController *naviController = (controller.parentViewController) ? controller.parentViewController.navigationController : controller.navigationController;
    if (isBackButtonImageExist && !isEmbedded) {
        if([controller conformsToProtocol:@protocol(UIGestureRecognizerDelegate)]){
            if(gestureDelegate){
                [naviController.interactivePopGestureRecognizer setEnabled:YES];
                naviController.interactivePopGestureRecognizer.delegate = gestureDelegate;
                
            }else{
                [naviController.interactivePopGestureRecognizer setEnabled:NO];
            }
        }
    }else{
        [naviController.interactivePopGestureRecognizer setEnabled:NO];
    }
}

@end
