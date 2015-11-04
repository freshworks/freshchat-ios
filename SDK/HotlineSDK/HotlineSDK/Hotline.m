//
//  Hotline.m
//  Konotor
//
//  Created by AravinthChandran on 9/7/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "Hotline.h"
#import "KonotorFeedbackScreen.h"
#import "KonotorEventHandler.h"
#import "HLContainerController.h"
#import "HLCategoriesListController.h"
#import "HLCategoryGridViewController.h"
#import "FDReachabilityManager.h"
#import "FDConversationController.h"
#import "HLChannelViewController.h"

@interface Hotline ()

@property(nonatomic, strong) FDReachabilityManager *globalReachabilityManager;

@end

@implementation Hotline

+(id)sharedInstance{
    static Hotline *sharedInstance = nil;
    static dispatch_once_t oncetoken;
    dispatch_once(&oncetoken,^{
        sharedInstance = [[Hotline alloc]init];
    });
    return sharedInstance;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.globalReachabilityManager = [[FDReachabilityManager alloc]initWithDomain:@"www.google.com"];
        [self.globalReachabilityManager start];
    }
    return self;
}

+(void)presentFeedback:(UIViewController *)controller{
    HLChannelViewController *channelViewController = [HLChannelViewController new];
    HLContainerController *containerController = [[HLContainerController alloc]initWithController:channelViewController];
    UINavigationController *navigationController = [[UINavigationController alloc]init];
    navigationController.viewControllers = @[containerController];
    [controller presentViewController:navigationController animated:YES completion:nil];
}

+(void)showFeedbackScreen{
    [KonotorFeedbackScreen showFeedbackScreen];
}

+(void)setSecretKey:(NSString *)key{
    [Konotor setSecretKey:key];
}

-(void)InitWithAppID:(NSString *)AppID AppKey:(NSString *)AppKey withDelegate:(id)delegate{
    if (delegate) {
        [Konotor InitWithAppID:AppID AppKey:AppKey withDelegate:delegate];
    }else{
        [Konotor InitWithAppID:AppID AppKey:AppKey withDelegate:[KonotorEventHandler sharedInstance]];
    }
}

+(void)setUnreadWelcomeMessage:(NSString *)text{
    [Konotor setUnreadWelcomeMessage:text];
}

+(void)presentSolutions:(UIViewController *)controller{
    HLCategoryGridViewController *categoryController = [[HLCategoryGridViewController alloc]init];
    HLContainerController *containerController = [[HLContainerController alloc]initWithController:categoryController];
    UINavigationController *navigationController = [[UINavigationController alloc]init];
    navigationController.viewControllers = @[containerController];
    [controller presentViewController:navigationController animated:YES completion:nil];
}

@end
