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
        [store setBoolValue:config.displaySolutionsAsGrid forKey:HOTLINE_DEFAULTS_DISPLAY_SOLUTION_AS_GRID];
        [store setBoolValue:config.cameraCaptureEnabled forKey:HOTLINE_DEFAULTS_CAMERA_CAPTURE_ENABLED];
        [store setBoolValue:config.agentAvatarEnabled forKey:HOTLINE_DEFAULTS_AGENT_AVATAR_ENABLED];
        [store setBoolValue:config.notificationSoundEnabled forKey:HOTLINE_DEFAULTS_NOTIFICATION_SOUND_ENABLED];
        [store setObject:config.secretKey forKey:HOTLINE_DEFAULTS_SECRET_KEY];
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
        if(user.countryCode && ![user.countryCode isEqualToString:@""]){
            [store setObject:user.phoneNumber forKey:HOTLINE_DEFAULTS_USER_USER_COUNTRY_CODE];
            userInfo[@"phoneCountry"] = user.countryCode;
        }
        
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
                    [self registerDeviceToken];
                    [self performPendingTasks];
                }
            }];
        }
        else {
            [self performPendingTasks];
        }
    });
}

-(void)registerDeviceToken{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    BOOL isAppRegistered = [store boolValueForKey:HOTLINE_DEFAULTS_IS_APP_REGISTERED];
    if (!isAppRegistered) {
        NSString *userAlias = [FDUtilities getUserAlias];
        NSString *token = [store objectForKey:HOTLINE_DEFAULTS_PUSH_TOKEN];
        [[[HLCoreServices alloc]init] registerAppWithToken:token forUser:userAlias handler:nil];
    }
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
    FDSecureStore *store = [FDSecureStore sharedInstance];
    BOOL isGridLayoutDisplayEnabled = [store boolValueForKey:HOTLINE_DEFAULTS_DISPLAY_SOLUTION_AS_GRID];
    if (isGridLayoutDisplayEnabled) {
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

#pragma mark Push notifications

-(void)addDeviceToken:(NSData *)deviceToken {
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *deviceTokenString = [[[deviceToken.description stringByReplacingOccurrencesOfString:@"<"withString:@""] stringByReplacingOccurrencesOfString:@">"withString:@""] stringByReplacingOccurrencesOfString:@" "withString:@""];
    if (deviceTokenString && ![deviceTokenString isEqualToString:@""]) {
        [store setObject:deviceTokenString forKey:HOTLINE_DEFAULTS_PUSH_TOKEN];
    }
    [self registerDeviceToken];
}

-(NSDictionary *)getPayloadFromNotificationInfo:(NSDictionary *)info{
    NSDictionary *payload = info;
    if (info[@"UIApplicationLaunchOptionsRemoteNotificationKey"]) {
        payload = info[@"UIApplicationLaunchOptionsRemoteNotificationKey"];
    }
    return payload;
}

-(BOOL)isHotlineNotification:(NSDictionary *)info{
    NSDictionary *payload = [self getPayloadFromNotificationInfo:info];
    return ([payload[@"source"] isEqualToString:@"konotor"] || [payload[@"source"] isEqualToString:@"hotline"]);
}

-(void)handleRemoteNotification:(NSDictionary *)info andAppstate:(UIApplicationState)appState{
    dispatch_async(dispatch_get_main_queue(), ^{

        [HLMessageServices downloadAllMessages:nil];

        NSDictionary *payload = [self getPayloadFromNotificationInfo:info];
        
        NSNumber *channelID = @([payload[@"kon_c_ch_id"] integerValue]);
        NSString *message = [payload valueForKeyPath:@"aps.alert"];
        HLChannel *channel = [HLChannel getWithID:channelID inContext:[KonotorDataManager sharedInstance].mainObjectContext];
        if (!channel) return;
        
        FDNotificationBanner *banner = [FDNotificationBanner sharedInstance];
        banner.delegate = self;
        banner.message.text = message;
        
        HLChannel *visibleChannel = [HotlineAppState sharedInstance].currentVisibleChannel;
                
        if(visibleChannel){
            if ([visibleChannel.channelID isEqual:channel.channelID]) {
                FDLog(@"Do not display notification banner / handle notification");
            }else{
                [banner displayBannerWithChannel:channel];
                FDLog(@"Display notification banner, user is in some other channel");
            }
        }else{
            if (appState == UIApplicationStateInactive) {
                [self launchMessageControllerOfChannel:channel];
                FDLog(@"Take user to the appropriate message screen");
            }else{
                [banner displayBannerWithChannel:channel];
                FDLog(@"Display notification banner, user is somewhere outside channel screen");
            }
        }
        
        FDLog(@"Push Recieved :%@", payload);
    });
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
    [self launchMessageControllerOfChannel:banner.currentChannel];
}

-(void)launchMessageControllerOfChannel:(HLChannel *)channel{
    UIViewController *visibleSDKController = [HotlineAppState sharedInstance].currentVisibleController;
    if (visibleSDKController) {
        FDLog(@"visible screen is inside SDK");
        if ([visibleSDKController isKindOfClass:[HLChannelViewController class]]) {
            [self pushMessageControllerFrom:visibleSDKController.navigationController withChannel:channel];
        } else if ([visibleSDKController isKindOfClass:[FDMessageController class]]) {
            FDMessageController *msgController = (FDMessageController *)visibleSDKController;
            if (msgController.isModal) {
                [self presentMessageControllerOn:visibleSDKController withChannel:channel];
            }else{
                UINavigationController *navController = msgController.navigationController;
                [navController popViewControllerAnimated:NO];
                [self pushMessageControllerFrom:navController withChannel:channel];
            }
        }else {
            [self presentMessageControllerOn:visibleSDKController withChannel:channel];
        }
        
    }else{
        [self presentMessageControllerOn:[self topMostController] withChannel:channel];
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