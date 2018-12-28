
//  Hotline.m
//  Konotor
//
//  Created by AravinthChandran on 9/7/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FreshchatSDK.h"
#import "FCContainerController.h"
#import "FCCategoryListController.h"
#import "FCCategoryGridViewController.h"
#import "FCAttachmentImageController.h"
#import "FCReachabilityManager.h"
#import "FCChannelViewController.h"
#import "FCDataManager.h"
#import "FCMessageController.h"
#import "FCSecureStore.h"
#import "FCMacros.h"
#import "FCUserUtil.h"
#import "FCMessageHelper.h"
#import "FCCoreServices.h"
#import "FCUtilities.h"
#import "FCSolutionUpdater.h"
#import "FCMessagesUpdater.h"
#import "FCMessages.h"
#import "FCConstants.h"
#import "FCMessageServices.h"
#import "FCUserProperties.h"
#import "FCUsers.h"
#import "FCVersionConstants.h"
#import "FCNotificationHandler.h"
#import "FCTagManager.h"
#import "FCArticlesController.h"
#import "FCArticleDetailViewController.h"
#import "FCFAQSearchIndex.h"
#import "FCMessageBinaries.h"
#import "FCLocalNotification.h"
#import "FCPlistManager.h"
#import "FCMemLogger.h"
#import "FCInterstitialViewController.h"
#import "FCControllerUtils.h"
#import "FCMessagePoller.h"
#import "FDThemeConstants.h"
#import "FCUtilities.h"
#import "FCLocaleUtil.h"
#import "FCLocaleConstants.h"
#import "FCRemoteConfig.h"
#import "FCLocalization.h"
#import "FCUserDefaults.h"
#import "FDImageView.h"
#import "FCVotingManager.h"
#import "FCJWTAuthValidator.h"
#import "FCJWTUtilities.h"
#import "FCJWTAuthValidator.h"

static BOOL FC_POLL_WHEN_APP_ACTIVE = NO;
#define FD_IMAGE_CACHE_DURATION 60 * 60 * 24 * 365


@interface FCNotificationBanner ()

-(void) resetView;

@end

@interface Freshchat ()

@property(nonatomic, strong, readwrite) FreshchatConfig *config;
@property (nonatomic, assign) BOOL showChannelThumbnail;
@property (nonatomic, strong) FCNotificationHandler *notificationHandler;
@property (nonatomic, strong) FCMessagePoller *messagePoller;

-(void)resetUserWithCompletion:(void (^)())completion init:(BOOL)doInit andOldUser:(NSDictionary*) previousUser;

-(void) updateLocaleMeta;

@end

@interface FreshchatUser ()

-(void)resetUser;

@end

@implementation FreshchatOptions

@end

@implementation Freshchat

+(instancetype)sharedInstance{
    
    static Freshchat *sharedInstance = nil;
    static dispatch_once_t oncetoken;
    dispatch_once(&oncetoken,^{
        sharedInstance = [[Freshchat alloc]init];
    });
    if(![sharedInstance checkPersistence]) { //Log on loggly
        [FCMemLogger sendMessage:@"COREDATA_EXCEPTION: Persistence not linked to Freshchat's SharedInstance" fromMethod:NSStringFromSelector(_cmd)];
    }
    return sharedInstance;
    
}

+(NSString *)SDKVersion{
    return FRESHCHAT_SDK_BUILD_NUMBER;
}

-(BOOL)checkPersistence {
    if(![[FCDataManager sharedInstance] isReady]){
        return false;
    }
    return true;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        [FCFAQSearchIndex load];
        [FCMessageBinaries load];
        [[FCReachabilityManager sharedInstance] start];
        [self registerAppNotificationListeners];
        self.messagePoller = [[FCMessagePoller alloc] initWithPollType:OffScreenPollFetch];
    }
    return self;
}

-(void)networkReachable{
    [FCUtilities initiatePendingTasks];
}

-(void)initWithConfig:(FreshchatConfig *)config{
    @try {
        [self initWithConfig:config completion:^(NSError *error) {
            if(error == nil) {
                [self newSession];
            }
        }];
    } @catch (NSException *exception) {
        [FCMemLogger sendMessage:exception.description fromMethod:NSStringFromSelector(_cmd)];
        if([exception.name isEqualToString: @"FreshchatInvalidArgumentException"]){
            @throw ([NSException exceptionWithName:exception.name reason:exception.description userInfo:nil]);
        }
    }
}

-(void)initWithConfig:(FreshchatConfig *)config completion:(void(^)(NSError *error))completion{
    FreshchatConfig *processedConfig = [self processConfig:config];
    
    self.config = processedConfig;
    if ([self hasUpdatedConfig:processedConfig]) {
        [FCUtilities updateAccountDeletedStatusAs:FALSE];
        [self cleanUpData:^{
            [self updateConfig:processedConfig andRegisterUser:completion];
        }];
    }
    else {
        [self updateConfig:processedConfig andRegisterUser:completion];
    }
}

-(FreshchatConfig *)processConfig:(FreshchatConfig *)config{
    config.appID  = trimString(config.appID);
    config.appKey = trimString(config.appKey);
    config.domain = [self validateDomain: config.domain];
    
    if(FC_POLL_WHEN_APP_ACTIVE){
        [self.messagePoller begin];
    }
    
    [self checkMediaPermissions:config];
    return config;
}

-(void)updateConfig:(FreshchatConfig *)config andRegisterUser:(void(^)(NSError *error))completion{
    FCSecureStore *store = [FCSecureStore sharedInstance];
    if (config) {
        
        if([config.appID isEqualToString: config.appKey] || (![FCUtilities isValidUUIDForKey:config.appID] && ![FCUtilities isValidUUIDForKey:config.appKey])){
            [self addInvalidAppIDKeyExceptionString:@"AppId or AppKey!"];
        }
        else if([FCUtilities isValidUUIDForKey:config.appID] && ![FCUtilities isValidUUIDForKey:config.appKey]){
            [self addInvalidAppIDKeyExceptionString:@"AppKey!"];
        }
        else if(![FCUtilities isValidUUIDForKey:config.appID] && [FCUtilities isValidUUIDForKey:config.appKey]){
            [self addInvalidAppIDKeyExceptionString:@"AppId!"];
        }
        [FDImageCache sharedImageCache].config.maxCacheAge = FD_IMAGE_CACHE_DURATION;
        [store setObject:config.stringsBundle forKey:HOTLINE_DEFAULTS_STRINGS_BUNDLE];
        [store setObject:config.appID forKey:HOTLINE_DEFAULTS_APP_ID];
        [store setObject:config.appKey forKey:HOTLINE_DEFAULTS_APP_KEY];
        [store setObject:config.domain forKey:HOTLINE_DEFAULTS_DOMAIN];
        [store setBoolValue:config.gallerySelectionEnabled forKey:HOTLINE_DEFAULTS_GALLERY_SELECTION_ENABLED];
        //[store setBoolValue:config.voiceMessagingEnabled forKey:HOTLINE_DEFAULTS_VOICE_MESSAGE_ENABLED];
        [store setBoolValue:config.cameraCaptureEnabled forKey:HOTLINE_DEFAULTS_CAMERA_CAPTURE_ENABLED];
        [store setBoolValue:config.teamMemberInfoVisible forKey:HOTLINE_DEFAULTS_AGENT_AVATAR_ENABLED];
        [store setBoolValue:config.notificationSoundEnabled forKey:HOTLINE_DEFAULTS_NOTIFICATION_SOUND_ENABLED];
        [store setBoolValue:config.showNotificationBanner forKey:HOTLINE_DEFAULTS_SHOW_NOTIFICATION_BANNER];
        [store setObject:config.themeName forKey:HOTLINE_DEFAULTS_THEME_NAME];
        [[FCTheme sharedInstance]setThemeWithName:config.themeName];
    }
    
    [FCJWTUtilities setTokenInitialState];
    [FCUserUtil registerUser:completion];
    if([FCUserUtil isUserRegistered]) {
        [FCUtilities postUnreadCountNotification];
    }
}

- (void) addInvalidAppIDKeyExceptionString :(NSString *) string{
    [NSException raise:@"FreshchatInvalidArgumentException" format:@"Initialization failed : FreshchatSDK initialized with invalid %@", string];
}

- (void) addInvalidMethodException : (NSString *) apiName {
    [NSException raise:@"FreshchatInvalidMethodException" format:@"API failed : FreshchatSDK failed with invalid API - %@", apiName];
}

-(void)checkMediaPermissions:(FreshchatConfig *)config{
    FCPlistManager *plistManager = [[FCPlistManager alloc] init];
    NSMutableString *message = [NSMutableString new];
    
    //    if (config.voiceMessagingEnabled) {
    //        if (![plistManager micUsageEnabled]) {
    //            [message appendString:@"\nAdd key NSMicrophoneUsageDescription : To Enable Voice Message"];
    //        }
    //    }
    
    if (config.gallerySelectionEnabled) {
        if (![plistManager photoLibraryUsageEnabled]) {
            [message appendString:@"\nAdd key NSPhotoLibraryUsageDescription : To Enable access to Photo Library"];
        }
    }
    if (config.cameraCaptureEnabled) {
        if (![plistManager cameraUsageEnabled]) {
            [message appendString:@"\nAdd key NSCameraUsageDescription : To take Images from Camera"];
        }
    }
    
    if (message.length > 0) {
        NSString *info = @"Warning! Freshchat SDK needs the following keys added to Info.plist for media access on iOS 10";
        ALog(@"\n\n** %@ ** \n %@ \n\n", info, message);
    }
}

-(void) registerAppNotificationListeners{
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(newSession)
                                                 name: UIApplicationDidBecomeActiveNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnteredBackground:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkReachable)
                                                 name:HOTLINE_NETWORK_REACHABLE object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(performPendingTasks)
                                                 name:HOTLINE_NOTIFICATION_PERFORM_PENDING_TASKS object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLocaleMeta)
                                                 name:FRESHCHAT_USER_LOCALE_CHANGED object:nil];
}

-(void)updateAppVersion{
    if([FCUserUtil isUserRegistered]){
        FCSecureStore *store = [FCSecureStore sharedInstance];
        NSString *storedValue = [store objectForKey:HOTLINE_DEFAULTS_APP_VERSION];
        NSString *currentValue = [[[NSBundle bundleForClass:[self class]] infoDictionary]objectForKey:@"CFBundleShortVersionString"];
        if (storedValue && ![storedValue isEqualToString:currentValue]) {
            [FCUserProperties createNewPropertyForKey:@"app_version" WithValue:currentValue isUserProperty:NO];
            [FCCoreServices uploadUnuploadedPropertiesWithForceUpdate:true];
        }
        [store setObject:currentValue forKey:HOTLINE_DEFAULTS_APP_VERSION];
    }
}

- (void)updateiOSVersion{
    if([FCUserUtil isUserRegistered]){
        NSString *storedIOSValue = [FCUserDefaults getStringForKey:FRESHCHAT_DEFAULTS_USER_IOS_VERSION];
        NSString *currentIOSValue = [[UIDevice currentDevice] systemVersion];
        if(!storedIOSValue){
            [FCUserDefaults setObject:[[UIDevice currentDevice] systemVersion] forKey:FRESHCHAT_DEFAULTS_USER_IOS_VERSION];
        }
        else if(storedIOSValue && ![storedIOSValue isEqualToString:currentIOSValue]){
            [FCCoreServices uploadUnuploadedPropertiesWithForceUpdate:true];
            [FCUserDefaults setObject:[[UIDevice currentDevice] systemVersion] forKey:FRESHCHAT_DEFAULTS_USER_IOS_VERSION];
        }
    }
}

-(void)updateSDKBuildNumber{
    FCSecureStore *store = [FCSecureStore sharedInstance];
    NSString *storedValue = [store objectForKey:HOTLINE_DEFAULTS_SDK_BUILD_NUMBER];
    NSString *currentValue = FRESHCHAT_SDK_BUILD_NUMBER;
    if (![storedValue isEqualToString:currentValue]) {
        [store setObject:FRESHCHAT_SDK_BUILD_NUMBER forKey:HOTLINE_DEFAULTS_SDK_BUILD_NUMBER];
        [FCCoreServices uploadUnuploadedPropertiesWithForceUpdate:true];
    }
}

-(void)cleanUpData:(void (^)())completion{
    FCDataManager *dataManager = [FCDataManager sharedInstance];
    NSDictionary *previousUser = [self getPreviousUserConfig];
    [dataManager deleteAllSolutions:^(NSError *error) {
        FDLog(@"All solutions deleted");
        [dataManager deleteAllIndices:^(NSError *error) {
            FDLog(@"Index cleared");
            [self resetUserWithCompletion:completion init:false andOldUser:previousUser];
        }];
    }];
}

-(NSDictionary *) getPreviousUserConfig{
    FCSecureStore *store = [FCSecureStore sharedInstance];
    NSDictionary *previousUserInfo = nil;
    if( [FCUserUtil isUserRegistered] &&
       [store objectForKey:HOTLINE_DEFAULTS_APP_ID] &&
       [store objectForKey:HOTLINE_DEFAULTS_APP_KEY] &&
       [store objectForKey:HOTLINE_DEFAULTS_DOMAIN] &&
       [FCUtilities currentUserAlias]){
        previousUserInfo =  @{ @"appId" : [store objectForKey:HOTLINE_DEFAULTS_APP_ID],
                               @"appKey" : [store objectForKey:HOTLINE_DEFAULTS_APP_KEY],
                               @"userAlias" :[FCUtilities currentUserAlias],
                               @"domain" : [store objectForKey:HOTLINE_DEFAULTS_DOMAIN]
                               };
    }
    return previousUserInfo;
}

-(BOOL)hasUpdatedConfig:(FreshchatConfig *)config{
    FCSecureStore *store = [FCSecureStore sharedInstance];
    NSDictionary *oldUserInfo = [store objectForKey:HOTLINE_DEFAULTS_OLD_USER_INFO];
    NSString *existingDomainName = [store objectForKey:HOTLINE_DEFAULTS_DOMAIN];
    NSString *existingAppID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *existingAppKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];
    if(!existingDomainName && !existingAppID && !existingAppKey && oldUserInfo){
        existingDomainName = oldUserInfo[@"domain"];
        existingAppID      = oldUserInfo[@"appId"];
        existingAppKey     = oldUserInfo[@"appKey"];
    }
    if ((existingDomainName && ![existingDomainName isEqualToString:@""])&&(existingAppID && ![existingAppID isEqualToString:@""])&&(existingAppKey && ![existingAppKey isEqualToString:@""])) {
        return (![existingDomainName isEqualToString:config.domain] || ![existingAppID isEqualToString:config.appID] || ![existingAppKey isEqualToString:config.appKey]) ? YES : NO;
    }else{
        //This is first launch, do not treat this as config update.
        [FCUtilities removeUUIDWithAppID:config.appID];
        FDLog(@"First launch");
        return NO;
    }
}

-(void) updateConversationBannerMessage:(NSString *) message{
    FCSecureStore *store = [FCSecureStore sharedInstance];
    [store setObject:message forKey:HOTLINE_DEFAULTS_CONVERSATION_BANNER_MESSAGE];
    [FCLocalNotification post:HOTLINE_BANNER_MESSAGE_UPDATED];
}

-(void)setUser:(FreshchatUser *)user{
    if([[FCRemoteConfig sharedInstance] isUserAuthEnabled]){
        ALog(@"Freshchat API : JWT is Enabled for thisb please use setUserWithIdToken!");
        return;
    }
    [FCUsers storeUserInfo:user];
    [FCCoreServices uploadUnuploadedProperties];
}


- (NSString *) getFreshchatUserId{
    return [FCUtilities getUserAliasWithCreate];
}

- (NSString *)getUserIdTokenStatus{
    switch ([[FCJWTAuthValidator sharedInstance] getDefaultJWTState]) {
        case 1:
            return @"TOKEN_VALID";
        case 2:
            return @"TOKEN_NOT_SET";
        case 3:
            return @"TOKEN_NOT_PROCESSED";
        case 4:
            return @"TOKEN_EXPIRED";
        case 5:
            return @"TOKEN_INVALID";
        default:
            return @"TOKEN_NOT_SET";
    }
}

- (void) setUserWithIdToken :(NSString *) jwtIdToken {
    
    [FCJWTUtilities removePendingRestoreJWTToken];
    [FCUtilities removeFlagToDisableUserPropUpdate];
    if(![FCJWTUtilities canProgressSetUserForToken:jwtIdToken]) return;
    
    if([[FCSecureStore sharedInstance] boolValueForKey:FRESHCHAT_DEFAULTS_IS_FIRST_AUTH]) {
        //TODO: Should not set to Expired state should rework
        [[FCJWTAuthValidator sharedInstance] updateAuthState:TOKEN_EXPIRED];
    } else {
        [[FCJWTAuthValidator sharedInstance] updateAuthState:TOKEN_NOT_SET];
    }
    
    //To store if internet is not available
    [FCJWTUtilities setPendingJWTToken:jwtIdToken];
    if(![FCUtilities isRemoteConfigFetched] && [[FCReachabilityManager sharedInstance] isReachable]){
        [self performPendingTasks];
        return;
    }
    [FCCoreServices validateJwtToken:jwtIdToken completion:^(BOOL valid, NSError *error) {
        if(!error && valid) {
            [FCUsers updateUserWithIdToken:jwtIdToken]; 
            [[FCJWTAuthValidator sharedInstance] updateAuthState:TOKEN_VALID];
            [FCUtilities initiatePendingTasks];
        } else {
            if([[FCReachabilityManager sharedInstance] isReachable]) {
                [FCCoreServices resetUserData:^{
                    [FCUtilities processResetChanges];
                    [FCUsers updateUserWithIdToken:jwtIdToken];
                    [[FCJWTAuthValidator sharedInstance] updateAuthState:TOKEN_INVALID];
                }];
            }
        }
    }];
}

-(void)restoreUserWithIdToken:(NSString *) jwtIdToken{
    [FCJWTUtilities removePendingJWTToken];
    
    if(![FCJWTUtilities canProgressUserRestoreForToken:jwtIdToken]) return;
    
    if ([FCJWTUtilities getReferenceID:jwtIdToken]) {
        [FCJWTUtilities setPendingRestoreJWTToken:jwtIdToken];
        
        if(![FCUtilities isRemoteConfigFetched] && [[FCReachabilityManager sharedInstance] isReachable]){
            [self performPendingTasks];
            return;
        }
        [FCUtilities resetDataAndRestoreWithJwtToken:jwtIdToken withCompletion:nil];
    } else {
        ALog(@"Freshchat : JWT reference id missing.");
    }
}

-(void)identifyUserWithExternalID:(NSString *) externalID restoreID:(NSString *) restoreID {
    if([[FCRemoteConfig sharedInstance] isUserAuthEnabled]){
        ALog(@"Freshchat : identifyUserWithExternalID is not allowed in auth strict mode");
    }
    if(externalID == nil) { //Safety check
        return;
    }
    NSString *oldExternalID = [FreshchatUser sharedInstance].externalID;
    NSString *oldRestoreID = [FreshchatUser sharedInstance].restoreID;
    oldExternalID = oldExternalID ? oldExternalID : @"";
    externalID = externalID ? externalID : @"";
    oldRestoreID = oldRestoreID ? oldRestoreID : @"";
    restoreID = restoreID ? restoreID : @"";
    
    if (([oldRestoreID length] == 0) && ([oldExternalID length] == 0) ) { // E0 R0
        if  (([externalID length] > 0) && ([restoreID length] > 0)) {
            // E0 R0 -> E1 -> R1
            //Flush and restore
            FDLog(@"E0 R0 -> E1 -> R1");
            [FCUtilities resetDataAndRestoreWithExternalID:externalID withRestoreID:restoreID withCompletion:nil];
        } else  if (([externalID length] > 0) && ([restoreID length] == 0)) {
            // E0 R0 -> E1 -> R0
            // Update to the local user data
            FDLog(@"E0 R0 -> E1 -> R0");
            FreshchatUser *user = [FreshchatUser sharedInstance];
            user.externalID = externalID;
            [[Freshchat sharedInstance]setUser:user];
        }
     } else if (([oldRestoreID length] > 0) && ([oldExternalID length] > 0)) { // E1 R1
         if (([externalID length] > 0) && ([restoreID length] > 0)) { // EY RY
             // EX RX -> EY -> RY
             //Flush and restore
            if( ![oldRestoreID isEqualToString:restoreID] && ![oldExternalID isEqualToString:externalID]) {
                 FDLog(@"EX RX -> EY -> RY Different E & R");
            } else if( [oldRestoreID isEqualToString:restoreID] && ![oldExternalID isEqualToString:externalID]) {
                 FDLog(@"EX RX -> EY -> RY Different E Same R");
            } else if( ![oldRestoreID isEqualToString:restoreID] && [oldExternalID isEqualToString:externalID]) {
                 FDLog(@"EX RX -> EY -> RY Same E Different R");
            }
            if( ![oldRestoreID isEqualToString:restoreID] || ![oldExternalID isEqualToString:externalID]) {
                [FCUtilities resetDataAndRestoreWithExternalID:externalID withRestoreID:restoreID withCompletion:nil];
            }
         } else if (([externalID length] > 0) && ([restoreID length] == 0)) { // EY R0
            if (![oldExternalID isEqual:externalID]) {
                // E1 R1 - > E2 R0
                FDLog(@"E1 R1 - > E2 R0");
                [FCUtilities resetDataAndRestoreWithExternalID:externalID withRestoreID:restoreID withCompletion:^{
                    FreshchatUser* oldUser = [FreshchatUser sharedInstance];
                    oldUser.externalID = externalID;
                    oldUser.restoreID = nil;
                    [FCUtilities resetAlias];
                    [[Freshchat sharedInstance] setUser:oldUser];
                    [FCUtilities initiatePendingTasks];
                }];
            }
        }
     } else if (([oldRestoreID length] == 0) && ([oldExternalID length] > 0) && ([externalID length] > 0) && ([restoreID length] > 0)) { // E1 R0
         // E1 R0 -> E1 -> R1
         //Flush and restore
         FDLog(@"E1 R0 -> E1 -> R1");
         [FCUtilities resetDataAndRestoreWithExternalID:externalID withRestoreID:restoreID withCompletion:nil];
     }
}

-(void)setUserProperties:(NSDictionary*)props{
    if([[FCRemoteConfig sharedInstance] isUserAuthEnabled]){
        ALog(@"Freshchat API : JWT is Enabled.");
        return;
    }
    [[FCDataManager sharedInstance].mainObjectContext performBlock:^{
        NSDictionary *filteredProps = [FCUtilities filterValidUserPropEntries:props];
        if(filteredProps){
            for(NSString *key in filteredProps){
                NSString *value = props[key];
                [FCUserProperties createNewPropertyForKey:key WithValue:value isUserProperty:NO];
            }
        }
        [FCCoreServices uploadUnuploadedProperties];
    }];
}

-(void)updateUserLocaleProperties:(NSString *)locale {
    [[FCDataManager sharedInstance].mainObjectContext performBlock:^{
        [FCUserProperties createNewPropertyForKey:LOCALE WithValue:locale isUserProperty:YES];
        [FCCoreServices uploadUnuploadedPropertiesWithForceUpdate:true];
    }];
}



-(void)setUserPropertyforKey:(NSString *) key withValue:(NSString *)value{
    if([[FCRemoteConfig sharedInstance] isUserAuthEnabled]){
        ALog(@"Freshchat API : JWT is Enabled.");
        return;
    }
    if (key && value) {
        [self setUserProperties:@{ key : value}];
    }
    else {
        ALog(@"Null property %@ provided. Not updated", key ? @"value" : @"key" );
    }
}

-(void)registerDeviceToken{
    FCSecureStore *store = [FCSecureStore sharedInstance];
    if([FCUserUtil isUserRegistered]){
        BOOL isDeviceTokenRegistered = [store boolValueForKey:HOTLINE_DEFAULTS_IS_DEVICE_TOKEN_REGISTERED];
        if (!isDeviceTokenRegistered) {
            if([FCUserUtil isUserRegistered] && [FCRemoteConfig sharedInstance].accountActive){
                NSString *userAlias = [FCUtilities currentUserAlias];
                NSString *token = [store objectForKey:HOTLINE_DEFAULTS_PUSH_TOKEN];
                [[[FCCoreServices alloc]init] registerAppWithToken:token forUser:userAlias handler:nil];
            }
        }
    }
    else {
        FDLog(@"Not updating device token : Register user first");
    }
}

/*  This function is called during every launch &
 when the SDK's app is transitioned from background to foreground  */

-(void)newSession{
    if([FCUtilities hasInitConfig]) {
        if(FC_POLL_WHEN_APP_ACTIVE){
            [self.messagePoller begin];
        }
        [FCUtilities initiatePendingTasks];
    }
}

-(void)handleEnteredBackground:(NSNotification *)notification{
    //save last message session
    [self.messagePoller end];
    [self updateSessionInterval];
}

- (void) updateSessionInterval{
    if([FCUserUtil isUserRegistered]){
        [FCUserDefaults setObject:[NSDate date] forKey:FRESHCHAT_DEFAULTS_SESSION_UPDATED_TIME];
    }
}

-(void) updateLocaleMeta {
    if([FCLocaleUtil hadLocaleChange])  {
        NSString *localLocale = [FCLocaleUtil getLocalLocale];
        [FCLocaleUtil updateLocaleWith:localLocale];
        [[Freshchat sharedInstance] updateUserLocaleProperties:localLocale];
        [[FCSecureStore sharedInstance] removeObjectWithKey:FC_SOLUTIONS_LAST_REQUESTED_TIME];
        [[FCSecureStore sharedInstance] removeObjectWithKey:FC_CHANNELS_LAST_REQUESTED_TIME];
        [FCUtilities initiatePendingTasks];
        [[FCNotificationBanner sharedInstance] resetView];
    }
}

-(void)performPendingTasks{
    FDLog(@"Performing pending tasks");
    [FCJWTUtilities performPendingJWTTasks];
    if ([FCUserUtil canRegisterUser]) {
        [FCUserUtil registerUser:nil];
    }
    if([FCUtilities hasInitConfig]) {
        [FCCoreServices performDAUCall];
        if([FCUtilities canMakeRemoteConfigCall]){
            [FCCoreServices fetchRemoteConfig];
        }
        dispatch_async(dispatch_get_main_queue(),^{
            if([FCUserUtil isUserRegistered]){
                [FCCoreServices performHeartbeatCall];
                if([FCUtilities canMakeSessionCall]){
                    [FCCoreServices performSessionCall];
                    [self updateSessionInterval];
                }
                [self registerDeviceToken];
                //TODO: Make all update methods as single method
                [self updateAppVersion];
                [self updateiOSVersion];
                [self updateAdId];
                [self updateSDKBuildNumber];
                [FCCoreServices uploadUnuploadedProperties];
                [FCMessages uploadAllUnuploadedMessages];
                [FCMessageServices uploadUnuploadedCSAT];
            } else {
                [FCJWTUtilities setTokenInitialState];
            }
            [self updateLocaleMeta];
            [[[FCSolutionUpdater alloc]init] fetch];
            [FCMessageServices fetchChannelsAndMessagesWithFetchType:InitFetch
                                                             source : Init
                                                          andHandler:nil];
            [self markPreviousUserUninstalledIfPresent];
        });
    }
}

-(void) updateAdId{
    FCSecureStore *secureStore = [FCSecureStore sharedInstance];
    NSString *storedAdId = [secureStore objectForKey:HOTLINE_DEFAULTS_ADID];
    NSString *adId = [FCUtilities getAdID];
    if(adId && adId.length > 0 && ![adId isEqualToString:storedAdId]){
        [secureStore setObject:adId forKey:HOTLINE_DEFAULTS_ADID];
        [FCUserProperties createNewPropertyForKey:@"adId" WithValue:adId isUserProperty:YES];
    }
}

#pragma mark - Route controllers

-(void)showFAQs:(UIViewController *)controller{
    if([[FCRemoteConfig sharedInstance] isActiveFAQAndAccount]){
        [self showFAQs:controller withOptions:[FAQOptions new]];
    }
    else{
        [FCUtilities showAlertViewWithTitle:HLLocalizedString(LOC_FAQ_FEATURE_DISABLED_TEXT) message:nil andCancelText:@"Cancel"];
    }
}

-(void)showConversations:(UIViewController *)controller{
    if([[FCRemoteConfig sharedInstance] isActiveInboxAndAccount]){
        [self showConversations:controller withOptions:[ConversationOptions new]];
    }
    else{
        [FCUtilities showAlertViewWithTitle:HLLocalizedString(LOC_CHANNELS_FEATURE_DISABLED_TEXT) message:nil andCancelText:@"Cancel"];
    }
}

-(void)showFAQs:(UIViewController *)controller withOptions:(FAQOptions *)options{
    if([FCUtilities isAccountDeleted]){
        [FCUtilities showAlertViewWithTitle:HLLocalizedString(LOC_ERROR_MESSAGE_ACCOUNT_NOT_ACTIVE_TEXT) message:nil andCancelText:HLLocalizedString(LOC_ERROR_MESSAGE_ACCOUNT_NOT_ACTIVE_CANCEL)];
        return;
    }
    [FCControllerUtils presentOn:controller option:options];
}

- (void) showConversations:(UIViewController *)controller withOptions :(ConversationOptions *)options {
    if([FCUtilities isAccountDeleted]){
        [FCUtilities showAlertViewWithTitle:HLLocalizedString(LOC_ERROR_MESSAGE_ACCOUNT_NOT_ACTIVE_TEXT) message:nil andCancelText:HLLocalizedString(LOC_ERROR_MESSAGE_ACCOUNT_NOT_ACTIVE_CANCEL)];
        return;
    }
    [FCControllerUtils presentOn:controller option:options];
}

-(UIViewController*) getFAQsControllerForEmbed{
    return [self getFAQsControllerForEmbedWithOptions:[FAQOptions new]];
}

-(UIViewController*) getConversationsControllerForEmbed{
    return [self getConversationsControllerForEmbedWithOptions:[ConversationOptions new]];
}

-(UIViewController*) getConversationsControllerForEmbedWithOptions:(ConversationOptions *) convOptions{
    return [FCControllerUtils getEmbedded:convOptions];
}

-(UIViewController*) getFAQsControllerForEmbedWithOptions:(FAQOptions *) faqOptions{
    return [FCControllerUtils getEmbedded:faqOptions];
}

#pragma mark Push notifications

-(void)setPushRegistrationToken:(NSData *)deviceToken {
    NSString *deviceTokenString = [[[deviceToken.description stringByReplacingOccurrencesOfString:@"<"withString:@""] stringByReplacingOccurrencesOfString:@">"withString:@""] stringByReplacingOccurrencesOfString:@" "withString:@""];
    if ([self isDeviceTokenUpdated:deviceTokenString]) {
        [self storeDeviceToken:deviceTokenString];
        [self registerDeviceToken];
    }
}

-(void) storeDeviceToken:(NSString *) deviceTokenString{
    if (deviceTokenString) {
        FCSecureStore *store = [FCSecureStore sharedInstance];
        [store setObject:deviceTokenString forKey:HOTLINE_DEFAULTS_PUSH_TOKEN];
        [store setBoolValue:NO forKey:HOTLINE_DEFAULTS_IS_DEVICE_TOKEN_REGISTERED];
    }
}

-(BOOL)isDeviceTokenUpdated:(NSString *)newToken{
    FCSecureStore *store = [FCSecureStore sharedInstance];
    if (newToken && ![newToken isEqualToString:@""]) {
        NSString* storedDeviceToken = [store objectForKey:HOTLINE_DEFAULTS_PUSH_TOKEN];
        return (storedDeviceToken == nil || ![storedDeviceToken isEqualToString:newToken]);
    }else{
        return NO;
    }
}

-(void)openFreshchatDeeplink:(NSString *)linkStr
     viewController:(UIViewController *) viewController {
    BOOL hasProcessed = [FCUtilities handleLink:[[NSURL alloc]initWithString:linkStr] faqOptions:nil navigationController:viewController handleFreshchatLinks:YES];
    if(!hasProcessed) {
        NSLog(@"Freshchat Error: Link not processed.");
    }
}

-(BOOL)isFreshchatNotification:(NSDictionary *)info{
    @try {
        return [FCNotificationHandler isFreshchatNotification:info];
    } @catch (NSException *exception) {
        FCMemLogger *logger = [FCMemLogger new];
        [logger addMessage:exception.debugDescription withMethodName:NSStringFromSelector(_cmd)];
        [logger addErrorInfo:info];
        [logger upload];
    }
    return NO; // Return a valid value to avoid inconsistency
}

-(void)handleRemoteNotification:(NSDictionary *)info andAppstate:(UIApplicationState)appState{
    @try {
        if(![self isFreshchatNotification:info]){
            return;
        }
        [FCLocalNotification post:FRESHCHAT_ACTION_USER_ACTIONS info:@{@"action" :@"NOTIFICATION_RECEIVED"}];
        self.notificationHandler = [[FCNotificationHandler alloc]init];
        [self.notificationHandler handleNotification:info appState:appState];
    } @catch (NSException *exception) {
        FCMemLogger *logger = [FCMemLogger new];
        [logger addMessage:exception.debugDescription withMethodName:NSStringFromSelector(_cmd)];
        [logger addErrorInfo:info];
        [logger upload];
    }
}

-(void)resetUser{
    [self resetUserWithCompletion:nil init:true andOldUser:nil];
}

static BOOL CLEAR_DATA_IN_PROGRESS = NO;

-(void)resetUserWithCompletion:(void (^)())completion init:(BOOL)doInit andOldUser:(NSDictionary*) previousUser {
    if (CLEAR_DATA_IN_PROGRESS == NO) {
        CLEAR_DATA_IN_PROGRESS = YES;
        [self processClearUserData:^{
            CLEAR_DATA_IN_PROGRESS = NO;
            if(completion){
                completion();
            }
            ALog(@"Clear user data completed");
        } init:doInit andOldUser:previousUser];
    }
    else {
        ALog(@"Clear user data already in progress");
    }
}

-(void)processClearUserData:(void (^)())completion init:(BOOL)doInit andOldUser:(NSDictionary*) previousUser{
    FCSecureStore *store = [FCSecureStore sharedInstance];
    FreshchatConfig *config = [[FreshchatConfig alloc] initWithAppID:[store objectForKey:HOTLINE_DEFAULTS_APP_ID]
                                                           andAppKey:[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    if([store objectForKey:HOTLINE_DEFAULTS_DOMAIN]){
        config.domain = [store objectForKey:HOTLINE_DEFAULTS_DOMAIN];
    }
    config.teamMemberInfoVisible =[store boolValueForKey:HOTLINE_DEFAULTS_AGENT_AVATAR_ENABLED];
    //config.voiceMessagingEnabled = [store boolValueForKey:HOTLINE_DEFAULTS_VOICE_MESSAGE_ENABLED];
    config.gallerySelectionEnabled = [store boolValueForKey:HOTLINE_DEFAULTS_GALLERY_SELECTION_ENABLED];
    config.cameraCaptureEnabled = [store boolValueForKey:HOTLINE_DEFAULTS_CAMERA_CAPTURE_ENABLED];
    config.showNotificationBanner = [store boolValueForKey:HOTLINE_DEFAULTS_SHOW_NOTIFICATION_BANNER];
    if([store objectForKey:HOTLINE_DEFAULTS_THEME_NAME]){
        config.themeName = [store objectForKey:HOTLINE_DEFAULTS_THEME_NAME];
    } else {
        config.themeName = FD_DEFAULT_THEME_NAME;
    }
    
    //Clear FDWebImage user cache
    [[FDImageCache sharedImageCache] clearMemory];
    [[FDImageCache sharedImageCache] clearDiskOnCompletion:nil];
    
    if(!previousUser) {
        previousUser = [self getPreviousUserConfig];
    }
    
    NSString *deviceToken = [store objectForKey:HOTLINE_DEFAULTS_PUSH_TOKEN];
    BOOL isUserRegistered = [FCUserUtil isUserRegistered];
    BOOL isAccountDeleted = [FCUtilities isAccountDeleted];
    [[FreshchatUser sharedInstance]resetUser]; // This clear Sercure Store data as well.
    
    //Clear secure store
    [[FCSecureStore sharedInstance]clearStoreData];
    [[FCSecureStore persistedStoreInstance]clearStoreData];
    [[FCVotingManager sharedInstance].votedArticlesDictionary removeAllObjects];
    [FCUserDefaults clearUserDefaults];
    [store setBoolValue:isAccountDeleted forKey:FRESHCHAT_DEFAULTS_IS_ACCOUNT_DELETED];
    if(previousUser && isUserRegistered) {
        [self storePreviousUser:previousUser inStore:store];
    } else {
        [self storePreviousUser:nil inStore:store];
    }
    [self markPreviousUserUninstalledIfPresent];
    [[FCDataManager sharedInstance] cleanUpUser:^(NSError *error) {
        if(![FCUtilities isAccountDeleted]){
            if(doInit){
                if(!config.appID || !config.appKey){
                    ALog(@"Warning! Freshchat SDK has not been initialized and resetUser has been called");
                }
                else{
                    [self initWithConfig:config completion:completion];
                }
            }
            if (deviceToken) {
                [self storeDeviceToken:deviceToken];
            }
            [FCLocalNotification post:FRESHCHAT_USER_RESTORE_ID_GENERATED info:@{}];
            [FCUtilities initiatePendingTasks];
        }
        if (completion) {
            completion();
        }
        [FCUtilities postUnreadCountNotification];
    }];
}

-(void)resetUserWithCompletion:(void (^)())completion{
    [self resetUserWithCompletion:completion init:true andOldUser:nil];
}

-(void)unreadCountWithCompletion:(void (^)(NSInteger count))completion{
    FDLog(@"unreadCountWithCompletion:: Unread count function called.");
    [self unreadCountForTags:nil withCompletion:completion];
}

-(void)unreadCountForTags:(NSArray *)tags withCompletion:(void(^)(NSInteger count))completion{
    __block int count=0;
    if (completion) {
        FDLog(@"unreadCountForTags:: Unread tags count function called.");
        [FCMessageServices fetchChannelsAndMessagesWithFetchType:OffScreenPollFetch source:UnreadCount andHandler:^(NSError *error) {
            if(error) {
                completion(count);
                return;
            }
            else {
                if ([tags count] == 0) {
                    FDLog(@"unreadCountForTags:: Fetching count for all visible channel.");
                    [FCUtilities unreadCountInternalHandler:^(NSInteger count) {
                        completion(count);
                    }];
                } else {
                    FDLog(@"unreadCountForTags:: Fetching count only for matching channels.");
                    [[FCTagManager sharedInstance] getChannelsForTags:tags
                                                            inContext:[FCDataManager sharedInstance].mainObjectContext
                                                       withCompletion:^(NSArray<FCChannels *> * channels, NSError *error) {
                                                           for(FCChannels *channel in channels){
                                                               count += [channel unreadCount];
                                                           }
                                                           dispatch_async(dispatch_get_main_queue(), ^{
                                                               completion(count);
                                                           });
                                                       }];
                }
            }
        }];
    }
}

-(void) sendMessage:(FreshchatMessage *)messageObject{
    if([FCUtilities isAccountDeleted]){
        NSLog(@"%@", HLLocalizedString(LOC_ERROR_MESSAGE_ACCOUNT_NOT_ACTIVE_TEXT));
        return;
    }
    if([FCJWTUtilities isJWTTokenInvalid]){
        ALog(@"Freshchat Error : Please set the user with valid token first.");
        return;
    }
    if(messageObject.message.length == 0 || messageObject.tag.length == 0){
        return;
    }
    NSManagedObjectContext *mainContext = [[FCDataManager sharedInstance] mainObjectContext];
    [mainContext performBlock:^{
        [[FCTagManager sharedInstance] getChannelsForTags:@[messageObject.tag] inContext:mainContext withCompletion:^(NSArray<FCChannels *> *channels, NSError *error){
            FCChannels *channel;
            if(channels.count >=1){
                channel = [channels firstObject];  // 1 will have the match , if more than one. it is ordered by pos
            }
            if(!channel){
                channel = [FCChannels getDefaultChannelInContext:mainContext];
            }
            if(channel){
                FCConversations *conversation;
                NSSet *conversations = channel.conversations;
                if(conversations && [conversations count] > 0 ){
                    conversation = [conversations anyObject];
                }
                if([[FCRemoteConfig sharedInstance] isUserAuthEnabled]
                   && ([FreshchatUser sharedInstance].jwtToken == nil && ![[FreshchatUser sharedInstance].jwtToken isEqualToString:@""])){
                    ALog(@"Freshchat Error : Please Validate the user first.");
                    return;
                }
                [FCMessageHelper uploadMessageWithImage:nil textFeed:messageObject.message onConversation:conversation andChannel:channel];
            }
        }];
    }];
}

- (NSString *)validateDomain:(NSString*)domain{
    return [FCStringUtil replaceInString:trimString(domain) usingRegex:@"^http[s]?:\\/\\/" replaceWith:@""];
}

-(void)storePreviousUser:(NSDictionary *) previousUserInfo inStore:(FCSecureStore *)secureStore{
    [secureStore setObject:previousUserInfo forKey:HOTLINE_DEFAULTS_OLD_USER_INFO];
}

-(void)markPreviousUserUninstalledIfPresent{
    FCAPIClient *client = [FCAPIClient sharedInstance];
    if(client.FC_IS_USER_OR_ACCOUNT_DELETED) return;
    static BOOL inProgress = false; // performPendingTasks can be called twice so sequence
    FCSecureStore *store = [FCSecureStore sharedInstance];
    NSDictionary *previousUserInfo = [store objectForKey:HOTLINE_DEFAULTS_OLD_USER_INFO];
    if(previousUserInfo && !inProgress){
        inProgress = true;
        [FCCoreServices trackUninstallForUser:previousUserInfo withCompletion:^(NSError *error) {
            if(!error){
                [store removeObjectWithKey:HOTLINE_DEFAULTS_OLD_USER_INFO];
            }
            inProgress = false;
        }];
    }
}

-(void)dismissHotlineViewInController:(UIViewController *) controller
                       withCompletion: (void(^)())completion  {
    void (^clearHLControllers)() = ^void() {
        for(UIViewController *tempVC in controller.childViewControllers){
            if([tempVC isKindOfClass:[FCContainerController class]] ||
               [tempVC isKindOfClass:[UITabBarController class]] ) {
                UIViewController *firstViewController = [tempVC.childViewControllers firstObject];
                if([firstViewController isKindOfClass:[FCChannelViewController class]] ||
                   [firstViewController isKindOfClass:[FCCategoryGridViewController class]] ||
                   [firstViewController isKindOfClass:[FCListViewController class]] ||
                   [firstViewController isKindOfClass:[FCArticleDetailViewController class]] ||
                   [firstViewController isKindOfClass:[FCMessageController class]]  ) {
                    [tempVC dismissViewControllerAnimated:NO completion:completion];
                }
                
            } else if([tempVC isKindOfClass:[FCAttachmentImageController class]]) {
                [tempVC dismissViewControllerAnimated:NO completion:completion];
            }
        }
    };
    if(controller.presentedViewController){
        [self dismissHotlineViewInController:controller.presentedViewController
                              withCompletion:clearHLControllers];
    }
    else {
        clearHLControllers();
    }
}

-(void) dismissEmbededFreshchatViews {
    UIViewController *rootController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [self dismissHotlineViewInController:rootController withCompletion:nil];
    if(!rootController.isBeingPresented) { // Embeded case
        UITabBarController *tabBar = (UITabBarController*) rootController;
        if(tabBar!= nil) { //Tab bar case
            UIViewController *selectedVC = tabBar.selectedViewController;
            if(selectedVC!= nil) {
                NSMutableArray<UIViewController *> *viewControllers = [[NSMutableArray alloc]init];
                for(UIViewController *tempVC in selectedVC.childViewControllers) {
                    if([tempVC isKindOfClass:[FCContainerController class]]) { // Check for our Freshchat SDK screen
                        FCInterstitialViewController *interstitialController = [[FCInterstitialViewController alloc] initViewControllerWithOptions:nil andIsEmbed:YES];                        
                        UINavigationController *navigationController = (UINavigationController *)selectedVC;
                        if (interstitialController != nil && navigationController != nil) {
                            [viewControllers addObject:interstitialController];
                            [navigationController setViewControllers:viewControllers animated:NO];
                        }
                        break; //Set the top most custom screens if any with the current not supported support section
                    } else {
                        [viewControllers addObject:tempVC]; //Insert all the top most custom screens
                    }
                }
            }
        }
    }
}

-(void) dismissFreshchatViews {
    UIViewController *rootController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [self dismissHotlineViewInController:rootController withCompletion:nil];
}

@end
