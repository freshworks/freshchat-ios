//
//  Hotline.m
//  Konotor
//
//  Created by AravinthChandran on 9/7/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "Hotline.h"
#import "HLContainerController.h"
#import "HLCategoriesListController.h"
#import "HLCategoryGridViewController.h"
#import "FDReachabilityManager.h"
#import "HLChannelViewController.h"
#import "KonotorDataManager.h"
#import "FDMessageController.h"
#import "FDSecureStore.h"
#import "HLMacros.h"
#import "HotlineAppState.h"
#import "Konotor.h"
#import "HLCoreServices.h"
#import "FDUtilities.h"
#import "FDChannelUpdater.h"
#import "FDSolutionUpdater.h"
#import "KonotorMessage.h"
#import "WebServices.h"
#import "HLConstants.h"
#import "FDNotificationBanner.h"

@interface Hotline ()

@property(nonatomic, strong, readwrite) HotlineConfig *config;
@property(nonatomic, strong) FDReachabilityManager *globalReachabilityManager;

@end

@interface HotlineUser ()

-(void)clearUserData;

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

-(void)initWithConfig:(HotlineConfig *)config{
    [self initWithConfig:config andUser:nil];
}

-(void)initWithConfig:(HotlineConfig *)config andUser:(HotlineUser *)user{
    self.config = config;
    [self storeConfig:config];
    [self registerUser];
    [self updateUser:user];
    [HLCoreServices DAUCall];
    [self updateAppVersion];
    [self updateSDKBuildNumber];
}

-(void)updateAppVersion{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *storedValue = [store objectForKey:HOTLINE_DEFAULTS_APP_VERSION];
    NSString *currentValue = [[[NSBundle mainBundle]infoDictionary]objectForKey:@"CFBundleShortVersionString"];
    if (![storedValue isEqualToString:currentValue]) {
        [[[HLCoreServices alloc]init]updateUserProperties:@{@"meta" : @{ @"app_version" : currentValue } } handler:^(NSError *error) {
            if (!error) {
                [store setObject:currentValue forKey:HOTLINE_DEFAULTS_APP_VERSION];
            }
        }];
    }
}

-(void)updateSDKBuildNumber{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *storedValue = [store objectForKey:HOTLINE_DEFAULTS_SDK_BUILD_NUMBER];
    NSString *currentValue = HOTLINE_SDK_BUILD_NUMBER;
    if (![storedValue isEqualToString:currentValue]) {
        [[[HLCoreServices alloc]init]updateSDKBuildNumber:currentValue];
    }
}

-(void)storeConfig:(HotlineConfig *)config{
    if ([self hasUpdatedConfigWith:config]) {
        FDLog(@"Clearing Data for Config update");
    }
    
    FDSecureStore *store = [FDSecureStore sharedInstance];
    
    if (config) {
        [store setObject:config.appID forKey:HOTLINE_DEFAULTS_APP_ID];
        [store setObject:config.appKey forKey:HOTLINE_DEFAULTS_APP_KEY];
        [store setObject:config.domain forKey:HOTLINE_DEFAULTS_DOMAIN];
    }
}

-(BOOL)hasUpdatedConfigWith:(HotlineConfig *)config{
    return NO;
}

-(void)updateUser:(HotlineUser *)user{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    
    if (user) {
        if (user.userName) {
            [store setObject:user.userName forKey:HOTLINE_DEFAULTS_USER_NAME];
            userInfo[@"name"] = user.userName;
        }
        
        if ([FDUtilities isValidEmail:user.emailAddress]) {
            [store setObject:user.emailAddress forKey:HOTLINE_DEFAULTS_USER_EMAIL];
            userInfo[@"email"] = user.emailAddress;
        }else{
            NSString *exceptionName   = @"HOTLINE_SDK_INVALID_EMAIL_EXCEPTION";
            NSString *exceptionReason = @"You are attempting to set a null/invalid email address, Please provide a valid one";
            [[[NSException alloc]initWithName:exceptionName reason:exceptionReason userInfo:nil]raise];
        }
        
        if (user.phoneNumber) {
            [store setObject:user.phoneNumber forKey:HOTLINE_DEFAULTS_USER_PHONE_NUMBER];
            userInfo[@"phone"] = user.phoneNumber;
        }
        
        if (user.externalID) {
            [store setObject:user.externalID forKey:HOTLINE_DEFAULTS_USER_EXTERNAL_ID];
            userInfo[@"identifier"] = user.externalID;
        }
    }

    [[[HLCoreServices alloc]init]updateUserProperties:userInfo handler:nil];
}

-(void)setCustomUserPropertyForKey:(NSString *)key withValue:(NSString *)value{
    if (key && value){
        [[[HLCoreServices alloc]init]updateUserProperties:@{@"meta": @{key : value}} handler:nil];
    }
}

-(void)registerUser{
    dispatch_async(dispatch_get_main_queue(),^{
        BOOL isUserRegistered = [FDUtilities isUserRegistered];
        if (!isUserRegistered) {
            [[[HLCoreServices alloc]init] registerUser:^(NSError *error) {
                if (!error) {
                    [self performPendingTasks];
                }
            }];
        }
        else {
            [self performPendingTasks];
        }
    });
}

-(void)performPendingTasks{
    FDLog(@"Performing pending tasks");
    dispatch_async(dispatch_get_main_queue(),^{
        [[[FDChannelUpdater alloc]init] fetch];
        [[[FDSolutionUpdater alloc]init] fetch];
        [KonotorMessage uploadAllUnuploadedMessages];
        [KonotorConversation DownloadAllMessages];
    });
}

-(void)presentSolutions:(UIViewController *)controller{
    UIViewController *preferedController = nil;
    if (self.displaySolutionsAsGrid) {
        preferedController = [[HLCategoryGridViewController alloc]init];
    }else{
        preferedController = [[HLCategoriesListController alloc]init];
    }
    HLContainerController *containerController = [[HLContainerController alloc]initWithController:preferedController];
    UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:containerController];
    [controller presentViewController:navigationController animated:YES completion:nil];
}

-(void)presentFeedback:(UIViewController *)controller{
    [[KonotorDataManager sharedInstance]fetchAllVisibleChannels:^(NSArray *channels, NSError *error) {
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

#pragma mark Push notifications

-(void)addDeviceToken:(NSData *)deviceToken {
    NSString *deviceTokenString = [[[deviceToken.description stringByReplacingOccurrencesOfString:@"<"withString:@""] stringByReplacingOccurrencesOfString:@">"withString:@""] stringByReplacingOccurrencesOfString:@" "withString:@""];
    NSString *userAlias = [FDUtilities getUserAlias];
    FDSecureStore *store = [FDSecureStore sharedInstance];
    BOOL isAppRegistered = [store boolValueForKey:HOTLINE_DEFAULTS_IS_APP_REGISTERED];
    if (!isAppRegistered) {
        [[[HLCoreServices alloc]init] registerAppWithToken:deviceTokenString forUser:userAlias handler:nil];
    }
}

-(BOOL)isSourceHotline:(NSDictionary *)info{
    return ([info[@"source"] isEqualToString:@"konotor"] || [info[@"source"] isEqualToString:@"hotline"]);
}

-(void)handleRemoteNotification:(NSDictionary *)info withController:(UIViewController *)controller{
    
    FDLog(@"Push Recieved :%@", info);
    
    
    NSNumber *channelID = @([info[@"kon_c_ch_id"] integerValue]);
    NSString *message = [info valueForKeyPath:@"aps.alert"];
    
    HLChannel *channel = [HLChannel getWithID:channelID inContext:[KonotorDataManager sharedInstance].mainObjectContext];
    
    UIViewController *currentController = [HotlineAppState sharedInstance].currentVisibleController;
    FDNotificationBanner *banner = [FDNotificationBanner sharedInstance];
    banner.message.text = message;
    [banner displayBannerWithChannel:channel];

//    
//    if (currentController) {
//        FDLog(@"visible screen is inside SDK");
//    }else{
//        FDLog(@"visible screen is outside SDK");
//        if (!controller) {
//            controller = nil;
//        }
//    }
//
    
    [KonotorConversation DownloadAllMessages ];
}

-(void)clearUserData{
    [[HotlineUser sharedInstance]clearUserData];
    [[FDSecureStore persistedStoreInstance]clearStoreData];
    [[KonotorDataManager sharedInstance]deleteAllChannels:^(NSError *error) {
        FDLog(@"Deleted all channels and conversations");
    }];
    [self newSession];
}

-(void)newSession{
    [self registerUser];
}

@end