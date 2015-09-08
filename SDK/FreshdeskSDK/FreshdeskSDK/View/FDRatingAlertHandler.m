//
//  FDRatingView.m
//  FreshdeskSDK
//
//  Created by Aravinth on 11/08/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDRatingAlertHandler.h"
#import "FDSecureStore.h"
#import "FDUtilities.h"
#import "FDNewTicketViewController.h"
#import "FDNavigationBar.h"

@interface FDRatingAlertHandler ()

@property (strong, nonatomic) FDSecureStore *secureStore;

@end

@implementation FDRatingAlertHandler

-(FDSecureStore *)secureStore{
    if(!_secureStore){
        _secureStore = [FDSecureStore sharedInstance];
    }
    return _secureStore;
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    
    if (buttonIndex == 1) {
        NSString *appStoreID = [self.secureStore objectForKey:MOBIHELP_DEFAULTS_APP_STORE_ID];
        NSString *reviewURL  = [NSString stringWithFormat:@"https://itunes.apple.com/app/%@",appStoreID];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewURL]];
    }else if (buttonIndex == 2) {
        FDNewTicketViewController *newTicketViewController = [[FDNewTicketViewController alloc]initWithModalPresentationType:YES];
        UINavigationController *modalController = [[UINavigationController alloc]initWithNavigationBarClass:[FDNavigationBar class] toolbarClass:nil];
        [modalController setViewControllers:@[newTicketViewController]];
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        UIViewController *parentViewController = window.rootViewController;
        [parentViewController presentViewController:modalController animated:YES completion:nil];
    }else if (buttonIndex == [alertView cancelButtonIndex]){
        [FDUtilities stopFurtherReviewRequest];
    }

}

@end