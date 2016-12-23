//
//  Hotline.m
//  Konotor
//
//  Created by AravinthChandran on 9/7/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "Hotline.h"
#import "HLContainerController.h"
#import "HLCategoryListController.h"
#import "HLCategoryGridViewController.h"
#import "FDReachabilityManager.h"
#import "HLChannelViewController.h"
#import "KonotorDataManager.h"
#import "FDMessageController.h"
#import "FDSecureStore.h"
#import "HLMacros.h"
#import "Konotor.h"
#import "HLCoreServices.h"
#import "FDUtilities.h"
#import "FDChannelUpdater.h"
#import "FDSolutionUpdater.h"
#import "FDMessagesUpdater.h"
#import "FDDAUUpdater.h"
#import "KonotorMessage.h"
#import "HLConstants.h"
#import "HLMessageServices.h"
#import "KonotorCustomProperty.h"
#import "KonotorUser.h"
#import "HLVersionConstants.h"
#import "HLNotificationHandler.h"
#import "HLArticleTagManager.h"
#import "HLArticlesController.h"
#import "HLArticleDetailViewController.h"
#import "HLArticleUtil.h"
#import "FAQOptionsInterface.h"
#import "FDIndex.h"
#import "KonotorMessageBinary.h"
#import "FDLocalNotification.h"
#import "FDPlistManager.h"
#import "FDMemLogger.h"

@interface Hotline ()

@property(nonatomic, strong, readwrite) HotlineConfig *config;
@property (nonatomic, assign) BOOL showChannelThumbnail;
@property (nonatomic, strong) NSTimer *pollingTimer;
@property (nonatomic, strong) HLNotificationHandler *notificationHandler;

@end

@interface HotlineUser ()

-(void)clearUserData;

@end

@implementation Hotline

+(instancetype)sharedInstance{
    
    @try {
        static Hotline *sharedInstance = nil;
        static dispatch_once_t oncetoken;
        dispatch_once(&oncetoken,^{
            sharedInstance = [[Hotline alloc]init];
        });
        if(![sharedInstance checkPersistence]) {
            return nil;
        }
        return sharedInstance;

    } @catch (NSException *exception) {
        [FDMemLogger sendMessage:exception.description fromMethod:NSStringFromSelector(_cmd)];
        return nil; // Return a valid value to avoid inconsistency
    }
}

+(NSString *)SDKVersion{
    return HOTLINE_SDK_VERSION;
}

-(BOOL)checkPersistence {
    if(![KonotorDataManager sharedInstance].persistentStoreCoordinator){
        return false;
    }
    return true;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        [FDIndex load];
        [KonotorMessageBinary load];
        [[FDReachabilityManager sharedInstance] start];
        [self registerAppNotificationListeners];
    }
    return self;
}

-(void)networkReachable{
    [FDUtilities registerUser:nil];
}

-(void)initWithConfig:(HotlineConfig *)config{
    @try {
        [self initWithConfig:config completion:nil];
    } @catch (NSException *exception) {
        [FDMemLogger sendMessage:exception.description fromMethod:NSStringFromSelector(_cmd)];
    }
}

-(void)initWithConfig:(HotlineConfig *)config completion:(void(^)(NSError *error))completion{
    HotlineConfig *processedConfig = [self processConfig:config];
    
    self.config = processedConfig;
    
    if ([self hasUpdatedConfig:processedConfig]) {
        [self cleanUpData:^{
            [self updateConfig:processedConfig andRegisterUser:completion];
        }];
    }
    else {
        [self updateConfig:processedConfig andRegisterUser:completion];
    }
}

-(HotlineConfig *)processConfig:(HotlineConfig *)config{
    config.appID  = trimString(config.appID);
    config.appKey = trimString(config.appKey);
    config.domain = [self validateDomain: config.domain];

    if(config.pollWhenAppActive){
        [self startPoller];
    }

    [self checkMediaPermissions:config];
    return config;
}

-(void)updateConfig:(HotlineConfig *)config andRegisterUser:(void(^)(NSError *error))completion{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    if (config) {
        [store setObject:config.stringsBundle forKey:HOTLINE_DEFAULTS_STRINGS_BUNDLE];
        [store setObject:config.appID forKey:HOTLINE_DEFAULTS_APP_ID];
        [store setObject:config.appKey forKey:HOTLINE_DEFAULTS_APP_KEY];
        [store setObject:config.domain forKey:HOTLINE_DEFAULTS_DOMAIN];
        [store setBoolValue:config.pictureMessagingEnabled forKey:HOTLINE_DEFAULTS_PICTURE_MESSAGE_ENABLED];
        [store setBoolValue:config.voiceMessagingEnabled forKey:HOTLINE_DEFAULTS_VOICE_MESSAGE_ENABLED];
        [store setBoolValue:config.cameraCaptureEnabled forKey:HOTLINE_DEFAULTS_CAMERA_CAPTURE_ENABLED];
        [store setBoolValue:config.agentAvatarEnabled forKey:HOTLINE_DEFAULTS_AGENT_AVATAR_ENABLED];
        [store setBoolValue:config.notificationSoundEnabled forKey:HOTLINE_DEFAULTS_NOTIFICATION_SOUND_ENABLED];
        [store setBoolValue:config.showNotificationBanner forKey:HOTLINE_DEFAULTS_SHOW_NOTIFICATION_BANNER];
        [store setBoolValue:YES forKey:HOTLINE_DEFAULTS_SHOW_CHANNEL_THUMBNAIL];
        [[HLTheme sharedInstance]setThemeName:config.themeName];
    }
    
    [FDUtilities registerUser:completion];
}

-(void)checkMediaPermissions:(HotlineConfig *)config{
    FDPlistManager *plistManager = [[FDPlistManager alloc] init];
    NSMutableString *message = [NSMutableString new];

    if (config.voiceMessagingEnabled) {
        if (![plistManager micUsageEnabled]) {
            [message appendString:@"\nAdd key NSMicrophoneUsageDescription : To Enable Voice Message"];
        }
    }
    
    if (config.pictureMessagingEnabled) {
        if (![plistManager photoLibraryUsageEnabled]) {
            [message appendString:@"\nAdd key NSPhotoLibraryUsageDescription : To Enable access to Photo Library"];
        }
        
        if (![plistManager cameraUsageEnabled]) {
            [message appendString:@"\nAdd key NSCameraUsageDescription : To take Images from Camera"];
        }
    }
    
    if (message.length > 0) {
        NSString *info = @"Warning! Hotline SDK needs the following keys added to Info.plist for media access on iOS 10";
        NSLog(@"\n\n** %@ ** \n %@ \n\n", info, message);
    }
}

-(void) registerAppNotificationListeners{
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(newSession:)
                                                 name: UIApplicationDidBecomeActiveNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnteredBackground:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkReachable)
                                                 name:HOTLINE_NETWORK_REACHABLE object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(performPendingTasks)
                                                 name:HOTLINE_NOTIFICATION_PERFORM_PENDING_TASKS object:nil];
}

-(void)updateAppVersion{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *storedValue = [store objectForKey:HOTLINE_DEFAULTS_APP_VERSION];
    NSString *currentValue = [[[NSBundle bundleForClass:[self class]] infoDictionary]objectForKey:@"CFBundleShortVersionString"];
    if (storedValue && ![storedValue isEqualToString:currentValue]) {
        [KonotorCustomProperty createNewPropertyForKey:@"app_version" WithValue:currentValue isUserProperty:NO];
        [HLCoreServices uploadUnuploadedProperties];
    }
    [store setObject:currentValue forKey:HOTLINE_DEFAULTS_APP_VERSION];
}

-(void)updateSDKBuildNumber{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *storedValue = [store objectForKey:HOTLINE_DEFAULTS_SDK_BUILD_NUMBER];
    NSString *currentValue = HOTLINE_SDK_BUILD_NUMBER;
    if (![storedValue isEqualToString:currentValue]) {
        [[[HLCoreServices alloc]init]updateSDKBuildNumber:currentValue];
    }
}


-(void)cleanUpData:(void (^)())completion{
    KonotorDataManager *dataManager = [KonotorDataManager sharedInstance];
    NSDictionary *previousUser = [self getPreviousUserInfo];
    [dataManager deleteAllSolutions:^(NSError *error) {
        FDLog(@"All solutions deleted");
        [dataManager deleteAllIndices:^(NSError *error) {
            FDLog(@"Index cleared");
            [self clearUserDataWithCompletion:completion init:false andOldUser:previousUser];
        }];
    }];
}

-(NSDictionary *) getPreviousUserInfo{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSDictionary *previousUserInfo = nil;
    if( [FDUtilities isUserRegistered] && [store objectForKey:HOTLINE_DEFAULTS_APP_ID] && [store objectForKey:HOTLINE_DEFAULTS_APP_KEY]){
        previousUserInfo =  @{ @"appId" : [store objectForKey:HOTLINE_DEFAULTS_APP_ID],
                               @"appKey" : [store objectForKey:HOTLINE_DEFAULTS_APP_KEY],
                               @"userAlias" :[FDUtilities getUserAlias],
                               @"domain" : [store objectForKey:HOTLINE_DEFAULTS_DOMAIN]
                               };
    }
    return previousUserInfo;
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

-(void) updateConversationBannerMessage:(NSString *) message{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    [store setObject:message forKey:HOTLINE_DEFAULTS_CONVERSATION_BANNER_MESSAGE];
}

-(void)updateUser:(HotlineUser *)user{
    [KonotorUser storeUserInfo:user];
    [HLCoreServices uploadUnuploadedProperties];
}


-(void)updateUserProperties:(NSDictionary*)props{
    
    [[KonotorDataManager sharedInstance].mainObjectContext performBlock:^{
        NSDictionary *filteredProps = [FDUtilities filterValidUserPropEntries:props];
        if(filteredProps){
            for(NSString *key in filteredProps){
                NSString *value = props[key];
                [KonotorCustomProperty createNewPropertyForKey:key WithValue:value isUserProperty:NO];
            }
        }
        [HLCoreServices uploadUnuploadedProperties];
    }];
}

-(void)updateUserPropertyforKey:(NSString *) key withValue:(NSString *)value{
    if (key && value) {
        [self updateUserProperties:@{ key : value}];
    }
    else {
        NSLog(@"Null property %@ provided. Not updated", key ? @"value" : @"key" );
    }
}

-(void)registerDeviceToken{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    if([FDUtilities isUserRegistered]){
        BOOL isDeviceTokenRegistered = [store boolValueForKey:HOTLINE_DEFAULTS_IS_DEVICE_TOKEN_REGISTERED];
        if (!isDeviceTokenRegistered) {
            NSString *userAlias = [FDUtilities getUserAlias];
            NSString *token = [store objectForKey:HOTLINE_DEFAULTS_PUSH_TOKEN];
            [[[HLCoreServices alloc]init] registerAppWithToken:token forUser:userAlias handler:nil];
        }
    }
    else {
        FDLog(@"Not updating device token : Register user first");
    }
}


/*  This function is called during every launch &
    when the SDK's app is transitioned from background to foreground  */

-(void)newSession:(NSNotification *)notification{
    if(self.config.pollWhenAppActive){
        [self startPoller];
    }
    [FDUtilities initiatePendingTasks];
}

-(void)handleEnteredBackground:(NSNotification *)notification{
    [self cancelPoller];
}

-(void)performPendingTasks{
    FDLog(@"Performing pending tasks");
    dispatch_async(dispatch_get_main_queue(),^{
        [[[FDSolutionUpdater alloc]init] fetch];
        [KonotorMessage uploadAllUnuploadedMessages];
        [HLMessageServices fetchChannelsAndMessages:nil];
        [[[FDDAUUpdater alloc]init] fetch];
        [self registerDeviceToken];
        [self updateAppVersion];
        [self updateAdId];
        [self updateSDKBuildNumber];
        [HLCoreServices uploadUnuploadedProperties];
        [self markPreviousUserUninstalledIfPresent];
        
        // TODO: Implement a better retry mechanism, also has a timing issue need to fix it
        [HLMessageServices uploadUnuploadedCSAT];
    });
}

-(void) updateAdId{
    FDSecureStore *secureStore = [FDSecureStore sharedInstance];
    NSString *storedAdId = [secureStore objectForKey:HOTLINE_DEFAULTS_ADID];
    NSString *adId = [FDUtilities getAdID];
    if(adId && adId.length > 0 && ![adId isEqualToString:storedAdId]){
        [secureStore setObject:adId forKey:HOTLINE_DEFAULTS_ADID];
        [KonotorCustomProperty createNewPropertyForKey:@"adId" WithValue:adId isUserProperty:YES];
    }
}

-(HLViewController *)getPreferredCategoryController{
    return [self preferredCategoryController:[FAQOptions new]];
}

-(HLViewController *) preferredCategoryController:(FAQOptions *)options {
    HLViewController *preferedController = nil;
    if (options.showFaqCategoriesAsGrid) {
        preferedController = [[HLCategoryGridViewController alloc]init];
    }else{
        preferedController = [[HLCategoryListController alloc]init];
    }
    return preferedController;
}


-(void) selectFAQController:(FAQOptions *)options
                                  withCompletion : (void (^)(HLViewController *))completion{
    [[HLArticleTagManager sharedInstance] articlesForTags:[options tags]
                                                withCompletion:^(NSSet *articleIds)  {
        
        void (^faqOptionsCompletion)(HLViewController *) = ^(HLViewController * preferredViewController){
            [HLArticleUtil setFAQOptions:options andViewController:preferredViewController];
            completion(preferredViewController);
        };
        if([articleIds count] > 1 ){
            HLViewController *preferedController = nil;
            preferedController = [[HLArticlesController alloc]init];
            faqOptionsCompletion(preferedController);
        }
        else if([articleIds count] == 1 ) {
            NSManagedObjectContext *mContext = [KonotorDataManager sharedInstance].mainObjectContext;
            
            [mContext performBlock:^{
                HLViewController *preferedController = nil;
                HLArticle *article = [HLArticle getWithID:[articleIds anyObject] inContext:mContext];
                if(article){
                    preferedController = [HLArticleUtil getArticleDetailController:article];
                    faqOptionsCompletion(preferedController);
                }
                else { // This shouldn't happen but lets see
                    preferedController = [self preferredCategoryController:options];
                    faqOptionsCompletion(preferedController);
                }
            }];
        }
        else {
            HLViewController *preferedController = nil;
            [options filterByTags:@[] withTitle:@""]; // No Matching tags so no need to pass it around
            preferedController = [self preferredCategoryController:options];
            faqOptionsCompletion(preferedController);
        }
    }];
}

-(void)showFAQs:(UIViewController *)controller{
    HLViewController *preferredController = [self getPreferredCategoryController];
    HLContainerController *containerController = [[HLContainerController alloc]initWithController:preferredController andEmbed:NO];
    UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:containerController];
    [controller presentViewController:navigationController animated:YES completion:nil];
}

-(void)showFAQs:(UIViewController *)controller withOptions:(FAQOptions *)options{
     [self selectFAQController:options withCompletion:^(HLViewController *preferredController) {
         HLContainerController *containerController = [[HLContainerController alloc]initWithController:preferredController andEmbed:NO];
         UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:containerController];
         [controller presentViewController:navigationController animated:YES completion:nil];
    }];
}

-(void)showConversations:(UIViewController *)controller{
    [[KonotorDataManager sharedInstance]fetchAllVisibleChannels:^(NSArray *channelInfos, NSError *error) {
        if (!error) {
            HLContainerController *preferredController = nil;
            if (channelInfos.count == 1) {
                HLChannelInfo *channelInfo = [channelInfos firstObject];
                FDMessageController *messageController = [[FDMessageController alloc]initWithChannelID:channelInfo.channelID
                                                                                   andPresentModally:YES];
                preferredController = [[HLContainerController alloc]initWithController:messageController andEmbed:NO];
            }else{
                HLChannelViewController *channelViewController = [[HLChannelViewController alloc]init];
                preferredController = [[HLContainerController alloc]initWithController:channelViewController andEmbed:NO];
            }
            UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:preferredController];
            [controller presentViewController:navigationController animated:YES completion:nil];
        }
    }];
}

-(UIViewController *)getControllerForEmbed:(HLViewController*)controller{
    HLContainerController *preferredController =[[HLContainerController alloc]initWithController:controller andEmbed:YES];
    return preferredController;
}

-(UIViewController*) getFAQsControllerForEmbed{
    return [self getControllerForEmbed:[self preferredCategoryController:[FAQOptions new]]];
}

-(UIViewController*) getConversationsControllerForEmbed{
    HLViewController *controller;
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].mainObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_CHANNEL_ENTITY];
    request.predicate = [NSPredicate predicateWithFormat:@"isHidden == NO"];
    NSArray *results = [context executeFetchRequest:request error:nil];
    if (results.count == 1){
        HLChannelInfo *channelInfo = [results firstObject];
        controller = [[FDMessageController alloc]initWithChannelID:channelInfo.channelID andPresentModally:NO];
    }else{
        controller = [[HLChannelViewController alloc]init];
    }

    return [self getControllerForEmbed:controller];
}

#pragma mark Push notifications

-(void)updateDeviceToken:(NSData *)deviceToken {
    NSString *deviceTokenString = [[[deviceToken.description stringByReplacingOccurrencesOfString:@"<"withString:@""] stringByReplacingOccurrencesOfString:@">"withString:@""] stringByReplacingOccurrencesOfString:@" "withString:@""];
    if ([self isDeviceTokenUpdated:deviceTokenString]) {
        [self storeDeviceToken:deviceTokenString];
        [self registerDeviceToken];
    }
}

-(void) storeDeviceToken:(NSString *) deviceTokenString{
    if (deviceTokenString) {
        FDSecureStore *store = [FDSecureStore sharedInstance];
        [store setObject:deviceTokenString forKey:HOTLINE_DEFAULTS_PUSH_TOKEN];
        [store setBoolValue:NO forKey:HOTLINE_DEFAULTS_IS_DEVICE_TOKEN_REGISTERED];
    }
}

-(BOOL)isDeviceTokenUpdated:(NSString *)newToken{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    if (newToken && ![newToken isEqualToString:@""]) {
        NSString* storedDeviceToken = [store objectForKey:HOTLINE_DEFAULTS_PUSH_TOKEN];
        return (storedDeviceToken == nil || ![storedDeviceToken isEqualToString:newToken]);
    }else{
        return NO;
    }
}

-(BOOL)isHotlineNotification:(NSDictionary *)info{
    @try {
        return [HLNotificationHandler isHotlineNotification:info];
    } @catch (NSException *exception) {
        FDMemLogger *logger = [FDMemLogger new];
        [logger addMessage:exception.debugDescription withMethodName:NSStringFromSelector(_cmd)];
        [logger addErrorInfo:info];
        [logger upload];
    }
    return NO; // Return a valid value to avoid inconsistency
}

-(void)handleRemoteNotification:(NSDictionary *)info andAppstate:(UIApplicationState)appState{
    @try {
        if(![self isHotlineNotification:info]){
            return;
        }
        self.notificationHandler = [[HLNotificationHandler alloc]init];
        [self.notificationHandler handleNotification:info appState:appState];
    } @catch (NSException *exception) {
        FDMemLogger *logger = [FDMemLogger new];
        [logger addMessage:exception.debugDescription withMethodName:NSStringFromSelector(_cmd)];
        [logger addErrorInfo:info];
        [logger upload];
    }
}

-(void)clearUserData{
    [self clearUserDataWithCompletion:nil init:true andOldUser:nil];
}

-(void)clearUserDataWithCompletion:(void (^)())completion init:(BOOL)doInit andOldUser:(NSDictionary*) previousUser{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    HotlineConfig *config = [[HotlineConfig alloc] initWithAppID:[store objectForKey:HOTLINE_DEFAULTS_APP_ID]
                                                       andAppKey:[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    if([store objectForKey:HOTLINE_DEFAULTS_DOMAIN]){
        config.domain = [store objectForKey:HOTLINE_DEFAULTS_DOMAIN];
    }
    config.agentAvatarEnabled =[store boolValueForKey:HOTLINE_DEFAULTS_AGENT_AVATAR_ENABLED];
    config.voiceMessagingEnabled = [store boolValueForKey:HOTLINE_DEFAULTS_VOICE_MESSAGE_ENABLED];
    config.pictureMessagingEnabled = [store boolValueForKey:HOTLINE_DEFAULTS_PICTURE_MESSAGE_ENABLED];
    config.cameraCaptureEnabled = [store boolValueForKey:HOTLINE_DEFAULTS_CAMERA_CAPTURE_ENABLED];
    config.showNotificationBanner = [store boolValueForKey:HOTLINE_DEFAULTS_SHOW_NOTIFICATION_BANNER];
    
    if(!previousUser) {
        previousUser = [self getPreviousUserInfo];
    }
  
    NSString *deviceToken = [store objectForKey:HOTLINE_DEFAULTS_PUSH_TOKEN];
    
    [[HotlineUser sharedInstance]clearUserData];
    [[HLArticleTagManager sharedInstance]clear];
    
    //Clear secure store
    [[FDSecureStore sharedInstance]clearStoreData];
    [[FDSecureStore persistedStoreInstance]clearStoreData];
    
    if(previousUser) {
        [self storePreviousUser:previousUser inStore:store];
    }
    
    [[KonotorDataManager sharedInstance]deleteAllProperties:^(NSError *error) {
        [[KonotorDataManager sharedInstance]deleteAllChannels:^(NSError *error) {
            if(doInit){
                [self initWithConfig:config completion:completion];
            }else{
                if (completion) {
                    completion();
                }
            }
            if (deviceToken) {
                [self storeDeviceToken:deviceToken];
            }
        }];
    }];
}

-(void)clearUserDataWithCompletion:(void (^)())completion{
    [self clearUserDataWithCompletion:completion init:true andOldUser:nil];
}

-(NSInteger)unreadCount{
    NSManagedObjectContext *context = [[KonotorDataManager sharedInstance]mainObjectContext];
    
    NSFetchRequest *messageQuery = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_MESSAGE_ENTITY];
    messageQuery.predicate = [NSPredicate predicateWithFormat:@"messageRead == NO"];

    NSFetchRequest *csatQuery = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_CSAT_ENTITY];
    csatQuery.predicate = [NSPredicate predicateWithFormat:@"csatStatus == %d", CSAT_NOT_RATED];

    NSArray *unreadMessages = [context executeFetchRequest:messageQuery error:nil];
    NSArray *pendingCSATs = [context executeFetchRequest:csatQuery error:nil];

    return (unreadMessages.count + pendingCSATs.count);
}

-(void)unreadCountWithCompletion:(void (^)(NSInteger count))completion{
    [HLMessageServices fetchChannelsAndMessages:^(NSError *error) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                 completion([self unreadCount]);
            });
        }
    }];
}

-(void) sendMessage: (NSString *) message onChannel: (NSString *) channelName{
    if(!message){
        return;
    }
    NSManagedObjectContext *mainContext = [[KonotorDataManager sharedInstance] mainObjectContext];
    [mainContext performBlock:^{
        HLChannel *channel = nil;
        if(channelName){
            channel = [HLChannel getWithName:channelName inContext:mainContext];
        }
        if(!channel){ // match not found
            channel = [HLChannel getDefaultChannelInContext:mainContext];// Should use a default channel
        }
        if(channel){
            KonotorConversation *conversation = [channel primaryConversation];
            [Konotor uploadTextFeedback:message onConversation:conversation onChannel:channel];
        }
    }];
}

- (NSString *)validateDomain:(NSString*)domain
{
    return [FDStringUtil replaceInString:trimString(domain) usingRegex:@"^http[s]?:\\/\\/" replaceWith:@""];
}

// Polling changes

-(void)startPoller{
    if(![self.pollingTimer isValid]){
        self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:OFF_CHAT_SCREEN_POLL_INTERVAL target:self selector:@selector(pollNewMessages:)
                                                           userInfo:nil repeats:YES];
        FDLog(@"Start off-screen message poller");
    }
}

-(void) pollNewMessages:(id)sender{
    NSManagedObjectContext *mainContext = [[KonotorDataManager sharedInstance] mainObjectContext];
    [mainContext performBlock:^{
        if([KonotorMessage hasUserMessageInContext:mainContext]){
            [HLMessageServices fetchChannelsAndMessages:nil];
            FDLog(@"Triggering poller");
        }
        else {
            FDLog(@"POLLER: Not fetching updates .. No user messages present");
        }
        
    }];
}

-(void)cancelPoller{
    if([self.pollingTimer isValid]){
        [self.pollingTimer invalidate];
        FDLog(@"Cancel off-screen message poller");
    }
}

-(void)storePreviousUser:(NSDictionary *) previousUserInfo inStore:(FDSecureStore *)secureStore{
    [secureStore setObject:previousUserInfo forKey:HOTLINE_DEFAULTS_OLD_USER_INFO];
}

-(void)markPreviousUserUninstalledIfPresent{
    static BOOL inProgress = false; // performPendingTasks can be called twice so sequence
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSDictionary *previousUserInfo = [store objectForKey:HOTLINE_DEFAULTS_OLD_USER_INFO];
    if(previousUserInfo && !inProgress){
        inProgress = true;
        [HLCoreServices trackUninstallForUser:previousUserInfo withCompletion:^(NSError *error) {
            if(!error){
                [store removeObjectWithKey:HOTLINE_DEFAULTS_OLD_USER_INFO];
                inProgress = false;
            }
        }];
    }
}

@end
