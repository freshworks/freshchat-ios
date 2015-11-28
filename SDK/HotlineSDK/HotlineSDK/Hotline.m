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
#import "HLChannelViewController.h"
#import "KonotorDataManager.h"
#import "FDMessageController.h"

@interface Hotline ()

@property(nonatomic, strong) FDReachabilityManager *globalReachabilityManager;

@end

@implementation Hotline

+(instancetype)sharedInstance{
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
    [[KonotorDataManager sharedInstance]fetchAllChannels:^(NSArray *channels, NSError *error) {
        if (!error) {
            HLContainerController *preferredController = nil;
            if (channels.count == 1) {
                FDMessageController *messageController = [[FDMessageController alloc]initWithChannel:channels.firstObject
                                                                                   andPresentModally:YES];
                preferredController = [[HLContainerController alloc]initWithController:messageController];
            }else{
                HLChannelViewController *channelViewController = [[HLChannelViewController alloc]init];
                preferredController = [[HLContainerController alloc]initWithController:channelViewController];
            }
            UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:preferredController];
            [controller presentViewController:navigationController animated:YES completion:nil];
        }
    }];
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

-(void)presentSolutions:(UIViewController *)controller{
    UIViewController *preferedController = nil;
    if (self.dispalySolutionAsGrid) {
        preferedController = [[HLCategoryGridViewController alloc]init];
    }else{
        preferedController = [[HLCategoriesListController alloc]init];
    }
    HLContainerController *containerController = [[HLContainerController alloc]initWithController:preferedController];
    UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:containerController];
    [controller presentViewController:navigationController animated:YES completion:nil];
}

@end