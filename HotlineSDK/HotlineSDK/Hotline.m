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
#import "HLConstants.h"
#import "FDNotificationBanner.h"
#import "HLMessageServices.h"

@interface Hotline () <FDNotificationBannerDelegate>

@property(nonatomic, strong, readwrite) HotlineConfig *config;
@property(nonatomic, strong) UIViewController *preferredControllerForNotification;
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
    [self updateUser:user];
    [self registerUser];
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
    if ([self hasUpdatedConfig:config]) {
        KonotorDataManager *dataManager = [KonotorDataManager sharedInstance];
        [dataManager deleteAllSolutions:^(NSError *error) {
            FDLog(@"All solutions deleted");
            [dataManager deleteAllIndices:^(NSError *error) {
                FDLog(@"Index cleared");
                [self clearUserData];
                [self updateConfig:config];
            }];
        }];
    }
    [self updateConfig:config];
}

-(BOOL)hasUpdatedConfig:(HotlineConfig *)config{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *existingDomainName = [store objectForKey:HOTLINE_DEFAULTS_DOMAIN];
    NSString *existingAppID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    if ((existingDomainName && ![existingDomainName isEqualToString:@""])&&(existingAppID && ![existingAppID isEqualToString:@""])) {
        return (![existingDomainName isEqualToString:config.domain] || ![existingAppID isEqualToString:config.appID]) ? YES : NO;
    }else{
        //This is first launch, do not treat this as config update.
        FDLog(@"First launch");
        return NO;
    }
}

-(void)updateConfig:(HotlineConfig *)config{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    if (config) {
        [store setObject:config.appID forKey:HOTLINE_DEFAULTS_APP_ID];
        [store setObject:config.appKey forKey:HOTLINE_DEFAULTS_APP_KEY];
        [store setObject:config.domain forKey:HOTLINE_DEFAULTS_DOMAIN];
        [store setBoolValue:config.pictureMessagingEnabled forKey:HOTLINE_DEFAULTS_PICTURE_MESSAGE_ENABLED];
        [store setBoolValue:config.voiceMessagingEnabled forKey:HOTLINE_DEFAULTS_VOICE_MESSAGE_ENABLED];
    }
}

-(void)updateUser:(HotlineUser *)user{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    
    if (user) {
        if (user.userName && ![user.userName isEqualToString:@""]) {
            [store setObject:user.userName forKey:HOTLINE_DEFAULTS_USER_NAME];
            userInfo[@"name"] = user.userName;
        }
        
        if (user.emailAddress && [FDUtilities isValidEmail:user.emailAddress]) {
            [store setObject:user.emailAddress forKey:HOTLINE_DEFAULTS_USER_EMAIL];
            userInfo[@"email"] = user.emailAddress;
        }else{
            NSString *exceptionName   = @"HOTLINE_SDK_INVALID_EMAIL_EXCEPTION";
            NSString *exceptionReason = @"You are attempting to set a null/invalid email address, Please provide a valid one";
            [[[NSException alloc]initWithName:exceptionName reason:exceptionReason userInfo:nil]raise];
        }
        
        //TODO: Need to add country code, once backend allows it
        
        if (user.phoneNumber && ![user.phoneNumber isEqualToString:@""]) {
            [store setObject:user.phoneNumber forKey:HOTLINE_DEFAULTS_USER_PHONE_NUMBER];
            userInfo[@"phone"] = user.phoneNumber;
        }
        
        if (user.externalID && ![user.externalID isEqualToString:@""]) {
            [store setObject:user.externalID forKey:HOTLINE_DEFAULTS_USER_EXTERNAL_ID];
            userInfo[@"identifier"] = user.externalID;
        }
    }

    [[[HLCoreServices alloc]init]updateUserProperties:userInfo handler:nil];
}

-(void)setCustomUserPropertyForKey:(NSString *)key withValue:(NSString *)value{
    if (key.length > 0 && value.length > 0){
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
        [HLMessageServices downloadAllMessages:nil];
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

-(void)presentConversations:(UIViewController *)controller{
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

-(UIViewController *)getControllerForEmbed:(UIViewController*)controller{
    HLContainerController *preferredController =[[HLContainerController alloc]initWithController:controller];
    preferredController.isEmbeddable = YES;
    UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:preferredController];
    return navigationController;
}

-(UIViewController*) getSolutionsControllerForEmbed{
    HLCategoriesListController *categoriesViewController = [[HLCategoriesListController alloc]init];
    return [self getControllerForEmbed:categoriesViewController];
}

-(UIViewController*) getConversationsControllerForEmbed{
    UIViewController *controller;
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].mainObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_CHANNEL_ENTITY];
    request.predicate = [NSPredicate predicateWithFormat:@"isHidden == NO"];
    NSArray *results = [context executeFetchRequest:request error:nil];
    
    if (results.count == 1){
        controller = [[FDMessageController alloc]initWithChannel:results.firstObject andPresentModally:NO];
    }else{
        controller = [[HLChannelViewController alloc]init];
    }

    return [self getControllerForEmbed:controller];
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

-(BOOL)isHotlineNotification:(NSDictionary *)info{
    return ([info[@"source"] isEqualToString:@"konotor"] || [info[@"source"] isEqualToString:@"hotline"]);
}

-(void)handleRemoteNotification:(NSDictionary *)info withController:(UIViewController *)controller{
    
    if (controller) {
        self.preferredControllerForNotification = controller;
    }else{
        self.preferredControllerForNotification = nil;
    }
    
    NSNumber *channelID = @([info[@"kon_c_ch_id"] integerValue]);
    NSString *message = [info valueForKeyPath:@"aps.alert"];
    HLChannel *channel = [HLChannel getWithID:channelID inContext:[KonotorDataManager sharedInstance].mainObjectContext];
    
    FDNotificationBanner *banner = [FDNotificationBanner sharedInstance];
    banner.delegate = self;
    banner.message.text = message;
    
    HLChannel *visibleChannel = [HotlineAppState sharedInstance].currentVisibleChannel;

    if(visibleChannel){
        if ([visibleChannel.channelID isEqual:channel.channelID]) {
            FDLog(@"Do not display notification banner, user in the same channel");
        }else{
            [banner displayBannerWithChannel:channel];
        }
    }else{
        [banner displayBannerWithChannel:channel];
    }
    
    FDLog(@"Push Recieved :%@", info);
    [HLMessageServices downloadAllMessages:nil];
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

-(void)notificationBanner:(FDNotificationBanner *)banner bannerTapped:(id)sender{
    HLChannel *currentChannel = banner.currentChannel;
    UIViewController *visibleSDKController = [HotlineAppState sharedInstance].currentVisibleController;
    if (visibleSDKController) {
        FDLog(@"visible screen is inside SDK");
        if ([visibleSDKController isKindOfClass:[HLChannelViewController class]]) {
            [self pushMessageControllerFrom:visibleSDKController.navigationController withChannel:currentChannel];
        } else if ([visibleSDKController isKindOfClass:[FDMessageController class]]) {
            FDMessageController *msgController = (FDMessageController *)visibleSDKController;
            if (msgController.isModal) {
                [self presentMessageControllerOn:visibleSDKController withChannel:currentChannel];
            }else{
                HLChannel *currentControllerChannel = [HotlineAppState sharedInstance].currentVisibleChannel;
                if (![currentControllerChannel.channelID isEqualToNumber:currentChannel.channelID]) {
                    UINavigationController *navController = msgController.navigationController;
                    [navController popViewControllerAnimated:NO];
                    [self pushMessageControllerFrom:navController withChannel:currentChannel];
                }
            }
        }else {
            [self presentMessageControllerOn:visibleSDKController withChannel:currentChannel];
        }
        
    }else{
        FDLog(@"visible screen is outside SDK");
        if (self.preferredControllerForNotification) {
            [self presentMessageControllerOn:self.preferredControllerForNotification withChannel:currentChannel];
        }else{
            [self presentMessageControllerOn:[self topMostController] withChannel:currentChannel];
        }
    }
}

-(UIViewController*) topMostController {
    UIViewController *topController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}


-(void)pushMessageControllerFrom:(UINavigationController *)controller withChannel:(HLChannel *)channel{
    FDMessageController *conversationController = [[FDMessageController alloc]initWithChannel:channel andPresentModally:NO];
    HLContainerController *container = [[HLContainerController alloc]initWithController:conversationController];
    [controller pushViewController:container animated:YES];
}

-(void)presentMessageControllerOn:(UIViewController *)controller withChannel:(HLChannel *)channel{
    FDMessageController *messageController = [[FDMessageController alloc]initWithChannel:channel andPresentModally:YES];
    HLContainerController *containerController = [[HLContainerController alloc]initWithController:messageController];
    UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:containerController];
    [controller presentViewController:navigationController animated:YES completion:nil];
}

-(NSInteger)unreadCount{
    NSManagedObjectContext *context = [[KonotorDataManager sharedInstance]mainObjectContext];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"KonotorMessage"];
    request.predicate = [NSPredicate predicateWithFormat:@"messageRead == NO"];
    NSArray *messages = [context executeFetchRequest:request error:nil];
    return messages.count;
}

-(void)unreadCountWithCompletion:(void (^)(NSInteger count))completion{
    [HLMessageServices downloadAllMessages:^(NSError *error) {
        if (completion) completion([self unreadCount]);
    }];
}

@end