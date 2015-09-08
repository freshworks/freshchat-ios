//
//  Mobihelp.h
//  FreshdeskSDK
//
//  Created by balaji on 22/04/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDNetworkManager.h"
#import "Mobihelp.h"
#import "FDAPIClient.h"
#import "MobiHelpDatabase.h"
#import "FDFolderListViewController.h"
#import "FDCoreDataImporter.h"
#import "FDArticle.h"
#import "FDBreadCrumb.h"
#import "FDCustomData.h"
#import "FDNewTicketViewController.h"
#import "FDKit.h"
#import "FDProgressHUD.h"
#import "FDTicketListViewController.h"
#import "FDSecureStore.h"
#import "FDTag.h"
#import "FDArticleLauncher.h"
#import "FDRatingAlertHandler.h"
#import "FDDateUtil.h"
#import "FDTicketsUpdater.h"
#import "FDSolutionUpdater.h"
#import "MobihelpAppState.h"
#import "FDMacros.h"
#import "FDUtilities.h"
#import "FDConstants.h"
#import "FDArticleListViewController.h"
#import "FDArticleDetailViewController.h"
#import "FDCoreDataCoordinator.h"
#import <UIKit/UIKit.h>

@interface Mobihelp ()

@property (strong, nonatomic) FDSecureStore        *secureStore;
@property (strong, nonatomic) MobiHelpDatabase     *database;
@property (strong, nonatomic) FDRatingAlertHandler *ratingAlertHandler;
@property (atomic           ) BOOL                 mobihelpInitialized;
@property (strong, nonatomic) MobihelpAppState     *appState;

@end

@implementation Mobihelp

@synthesize userName = _userName, emailAddress = _emailAddress;

#pragma mark - Shared Manager

static Mobihelp *_sharedInstance = nil;

+ (id)sharedInstance {
    if(_sharedInstance == nil){
        @synchronized([Mobihelp class]){
            if(_sharedInstance == nil ){
                _sharedInstance = [[self alloc] init];
            }
        }
    }
    return _sharedInstance;
}

- (id) init {
    @synchronized([Mobihelp class]) {
        if(!_sharedInstance){
            self = [super init];
            _sharedInstance = self;
        }
    }
    return _sharedInstance;
}

 
#pragma mark - Lazy Instantiations

-(MobiHelpDatabase *)database{
    if(!_database){
        // TODO : Revisit this . May be use background context .. Or why even use database from here.
        _database = [[MobiHelpDatabase alloc] initWithContext:[[FDCoreDataCoordinator sharedInstance] getBackgroundContext]];
    }
    return _database;
}

-(FDSecureStore *)secureStore{
    if(!_secureStore){
        _secureStore = [FDSecureStore sharedInstance];
    }
    return _secureStore;
}

-(FDRatingAlertHandler *)ratingAlertHandler{
    if(!_ratingAlertHandler){
        _ratingAlertHandler = [[FDRatingAlertHandler alloc]init];
    }
    return _ratingAlertHandler;
}

-(MobihelpAppState *)appState{
    if(!_appState){
        _appState = [MobihelpAppState sharedMobihelpAppState];
    }
    return _appState;
}

#pragma mark - Username/Emailaddress

-(NSString *)userName{
    return [self.secureStore objectForKey:MOBIHELP_DEFAULTS_USER_NAME];
}

-(NSString *)emailAddress{
    return [self.secureStore objectForKey:MOBIHELP_DEFAULTS_USER_EMAIL_ADDRESS];
}

-(void)setUserName:(NSString *)userName{
    if (userName && trimString(userName).length > 0) {
        _userName = userName;
        [self.secureStore setObject:userName forKey:MOBIHELP_DEFAULTS_USER_NAME];
    }
}

-(void)setEmailAddress:(NSString *)emailAddress{
    if ([FDUtilities isValidEmail:emailAddress]) {
        _emailAddress = emailAddress;
        [self.secureStore setObject:emailAddress forKey:MOBIHELP_DEFAULTS_USER_EMAIL_ADDRESS];
        FDLog(@"API KEY : %@",[self.secureStore objectForKey:MOBIHELP_DEFAULTS_API_KEY]);
    }else{
        //Throw exception
        NSString *exceptionName   = @"MOBIHELP_SDK_INVALID_EMAIL_EXCEPTION";
        NSString *exceptionReason = @"You are attempting to set a null/invalid email address, Please provide a valid one";
        [[[NSException alloc]initWithName:exceptionName reason:exceptionReason userInfo:nil]raise];
    }
}


#pragma mark - Mobihelp Initializer

-(void)initWithConfig:(MobihelpConfig *)config{
    [self storeConfig:config];
    [[FDNetworkManager sharedNetworkManager]updateSerializer];
    [self registerApp];
    [FDUtilities incrementLaunchCount];
    [self automaticAppReviewRequest];
}

-(void)storeConfig:(MobihelpConfig *)config{
    if ([self hasUpdatedConfigWith:config]) {
        FDLog(@"Clearing Data for Config update");
        [self clearEverything];
    }
    [self.secureStore setObject:config.domain forKey:MOBIHELP_DEFAULTS_SUPPORT_SITE];
    [self.secureStore setObject:config.appKey forKey:MOBIHELP_DEFAULTS_APP_KEY];
    [self.secureStore setObject:config.appSecret forKey:MOBIHELP_DEFAULTS_APP_SECRET];
    [self.secureStore setBoolValue:config.prefetchSolutions forKey:MOBIHELP_DEFAULTS_SOLUTION_PREFETCH_PREFERENCE];
    [self.secureStore setBoolValue:config.enableSSL forKey:MOBIHELP_DEFAULTS_IS_SSL_ENABLED];
    [self.secureStore setIntValue:config.feedbackType forKey:MOBIHELP_DEFAULTS_APP_FEEDBACK_TYPE];
    [self.secureStore setBoolValue:config.enableAutoReply forKey:MOBIHELP_DEFAULTS_IS_AUTO_REPLY_ENABLED];
    [self.secureStore setBoolValue:config.enableEnhancedPrivacy forKey:MOBIHELP_DEFAULTS_IS_ENHANCED_PRIVACY_ENABLED];
    [self.secureStore setObject:config.appStoreId forKey:MOBIHELP_DEFAULTS_APP_STORE_ID];
    [self.secureStore setIntValue:config.launchCountForAppReviewPrompt forKey:MOBIHELP_DEFAULTS_APP_REVIEW_LAUNCH_COUNT];
    [self logAppState];
}

-(void)logAppState{
    [self.appState logAppState];
}

-(BOOL)hasUpdatedConfigWith:(MobihelpConfig *)config{
    NSString *existingDomainName = [self.secureStore objectForKey:MOBIHELP_DEFAULTS_SUPPORT_SITE];
    NSString *existingAppKey = [self.secureStore objectForKey:MOBIHELP_DEFAULTS_APP_KEY];
    return (![existingDomainName isEqualToString:config.domain] || ![existingAppKey isEqualToString:config.appKey]) ? YES : NO;
}

-(void)registerApp{
    [self registerDeviceForAppWithCompletion:^(NSError * error, BOOL isDeviceRegistered) {
        if (!error) {
            if(!isDeviceRegistered) {
                if ([self isPrefetchPreferred]){
                    [self fetchSolutionList];
                }
            }
        }else{
            NSLog(@"%@", error);
        }
        [self setMobihelpInitialized:YES];
        FDLog(@"Init Completed");
    }];
}

-(void)registerDeviceForAppWithCompletion:(void (^)(NSError *, BOOL))completion {
    BOOL isDeviceRegistered = [self.secureStore boolValueForKey:MOBIHELP_DEFAULTS_DEVICE_REGISTRATION_STATUS];
    FDAPIClient *webservice         = [[FDAPIClient alloc]init];
    FDCoreDataImporter *dataImporter = [[FDCoreDataImporter alloc]initWithContext:self.database.context webservice:webservice];
    if (!isDeviceRegistered) {
        [dataImporter registerDeviceWithCompletion:^(NSError * error) {
            completion(error, isDeviceRegistered);
        }];
    }else{
        completion(nil, isDeviceRegistered);
    }
}

-(BOOL)isPrefetchPreferred{
    return [self.secureStore boolValueForKey:MOBIHELP_DEFAULTS_SOLUTION_PREFETCH_PREFERENCE];
}

-(void)fetchSolutionList{
    FDSolutionUpdater *updater = [[FDSolutionUpdater alloc]init];
    [updater fetch];
}

-(void)launchAppReviewRequest{
    if ([FDUtilities hasUserPreferredAppReview] && ![FDUtilities metReviewRequestCycle]) {
        [self showReviewRequest];
    }
}

-(void)automaticAppReviewRequest{
    if ([FDUtilities metReviewRequestCycle]) {
        [self showReviewRequest];
    }
}

-(void)showReviewRequest{
    UIAlertView *ratingAlert = [[UIAlertView alloc] initWithTitle:FDLocalizedString(@"Rating Alert Title") message:FDLocalizedString(@"Rating Alert Message") delegate:self.ratingAlertHandler cancelButtonTitle:FDLocalizedString(@"Not Now") otherButtonTitles:FDLocalizedString(@"Rate Me"), FDLocalizedString(@"Send Feedback Button Text"), nil ];
    [ratingAlert show];
}

#pragma mark - Breadcrumbs and CustomData

- (void)leaveBreadcrumb:(NSString *)crumbDetails {
    [[FDBreadCrumb sharedInstance] addCrumb:crumbDetails];
}

- (void) addCustomDataForKey:(NSString *)key withValue:(NSString *)value{
    [[FDCustomData sharedInstance]addCustomDataWithKey:key andValue:value];
}

- (void) addCustomDataForKey:(NSString *)key withValue:(NSString *)value andSensitivity:(BOOL)isSensitive{
    [[FDCustomData sharedInstance] addCustomDatawithKey:key andValue:value andSensitivity:isSensitive];
}

#pragma mark - Support Window Setting

-(void)presentSupport:(UIViewController *)parentViewController{
    [self.secureStore setBoolValue:NO forKey:MOBIHELP_DEFAULTS_IS_CONVERSATIONS_DISABLED];
    FDFolderListViewController *folderListViewController = [[FDFolderListViewController alloc]init];
    UINavigationController *navigationController = [[UINavigationController alloc]initWithNavigationBarClass:[FDNavigationBar class] toolbarClass:nil];
    [navigationController setViewControllers:[NSArray arrayWithObject:folderListViewController]];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [parentViewController presentViewController:navigationController animated:YES completion:nil];
}

-(void)presentSolutions:(UIViewController *) parentViewController{
    [self.secureStore setBoolValue:YES forKey:MOBIHELP_DEFAULTS_IS_CONVERSATIONS_DISABLED];
    FDFolderListViewController *folderListViewController = [[FDFolderListViewController alloc]init];
    UINavigationController *navigationController = [[UINavigationController alloc]initWithNavigationBarClass:[FDNavigationBar class] toolbarClass:nil];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [navigationController setViewControllers:[NSArray arrayWithObject:folderListViewController]];
    [parentViewController presentViewController:navigationController animated:YES completion:nil];
}

-(void)presentSolutions:(UIViewController *) parentViewController withTags:(NSArray *) tagsArray{
    UINavigationController *navigationController = [[UINavigationController alloc]initWithNavigationBarClass:[FDNavigationBar class] toolbarClass:nil];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    if(tagsArray){
        tagsArray = [self convertToLowerCase:tagsArray];
        UIViewController *viewController = [FDArticleLauncher filterSolutionsUsing:tagsArray];
        [navigationController setViewControllers:[NSArray arrayWithObject:viewController]];
        [parentViewController presentViewController:navigationController animated:YES completion:nil];
    }
    else{
        FDFolderListViewController *folderListViewController = [[FDFolderListViewController alloc]init];
        [navigationController setViewControllers:[NSArray arrayWithObject:folderListViewController]];
        [parentViewController presentViewController:navigationController animated:YES completion:nil];
    }
}

-(NSArray *)convertToLowerCase:(NSArray *)tagsArray{
    NSMutableArray *mutableTagsArray = [tagsArray mutableCopy];
    [mutableTagsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        mutableTagsArray[idx] = [obj lowercaseString];
    }];
    tagsArray = mutableTagsArray;
    return tagsArray;
}

-(void)presentFeedback:(UIViewController *)parentViewController{
    BOOL isAppValid = [[MobihelpAppState sharedMobihelpAppState] isAppDisabled];
    if (isAppValid) {
        FDNewTicketViewController *newTicketViewController = [[FDNewTicketViewController alloc]initWithModalPresentationType:YES];
        UINavigationController *modalController = [[UINavigationController alloc]initWithNavigationBarClass:[FDNavigationBar class] toolbarClass:nil];
        [modalController setViewControllers:[NSArray arrayWithObject:newTicketViewController]];
        modalController.modalPresentationStyle = UIModalPresentationFormSheet;
        [parentViewController presentViewController:modalController animated:YES completion:nil];
    }else{
        [FDProgressHUD showErrorWithStatus:FDLocalizedString(@"app disabled error message")];
    }
}

-(void)presentInbox:(UIViewController *)parentViewController{
    BOOL isAppValid = [[MobihelpAppState sharedMobihelpAppState] isAppDisabled];
    if (isAppValid) {
        FDTicketListViewController *ticketListController = [[FDTicketListViewController alloc]init];
        UINavigationController *navigationController = [[UINavigationController alloc]initWithNavigationBarClass:[FDNavigationBar class] toolbarClass:nil];
        [navigationController setViewControllers:[NSArray arrayWithObject:ticketListController]];
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        [parentViewController presentViewController:navigationController animated:YES completion:nil];
    }else{
        [FDProgressHUD showErrorWithStatus:FDLocalizedString(@"app disabled error message")];
    }
}

#pragma mark - Unread Notes Count

-(NSInteger)unreadCount{
    return [self.database getOverallUnreadNotesCount];
}

-(void)unreadCountWithCompletion:(void(^)(NSInteger count))completion{
    FDTicketsUpdater *updater = [[FDTicketsUpdater alloc]init];
    [updater setIntervalInSecs:UNREAD_COUNT_UPDATE_INTERVAL];
    if ([updater hasTimedOut] && [self.appState isAppDisabled] && !self.appState.isAppInvalid) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            int maxWaitTime = 10;
            int waitTime = 0 ;
            int sleepTime = 1;
            while(![self mobihelpInitialized] && waitTime <= maxWaitTime){
                waitTime+=sleepTime;
                FDLog(@"\n\nWaiting for Init\n\n %d",waitTime);
                sleep(sleepTime);
            }
            if( waitTime < maxWaitTime) {
                [updater fetchWithCompletion:^(NSError *error) {
                    [self.database.context performBlock:^{
                        NSInteger unreadNotesCount = (!error) ? [self.database getOverallUnreadNotesCount] : 0;
                        dispatch_async(dispatch_get_main_queue(), ^{ if (completion) completion(unreadNotesCount); });
                    }];
                }];
            }
            else {
                [self.database.context performBlock:^{
                    NSInteger unreadNotesCount = [self.database getOverallUnreadNotesCount];
                    dispatch_async(dispatch_get_main_queue(), ^{ if (completion) completion(unreadNotesCount); });
                }];
            }
        });
    }else{
        [self.database.context performBlock:^{
            NSInteger unreadNotesCount = [self.database getOverallUnreadNotesCount];
            dispatch_async(dispatch_get_main_queue(), ^{ if (completion) completion(unreadNotesCount); });
        }];
    }
}


#pragma mark - Clear Data

-(void)clearUserData{

    NSArray *dataToRemove = @[MOBIHELP_DEFAULTS_USER_REGISTRATION_STATUS, MOBIHELP_DEFAULTS_API_KEY, MOBIHELP_DEFAULTS_SOLUTIONS_LAST_UPDATED_TIME_V2, MOBIHELP_DEFAULTS_TICKETS_LAST_UPDATED_TIME, MOBIHELP_DEFAULTS_APP_CONFIG_LAST_UPDATED_TIME, MOBIHELP_DEFAULTS_DEVICE_UUID, MOBIHELP_DEFAULTS_USER_NAME, MOBIHELP_DEFAULTS_USER_EMAIL_ADDRESS, MOBIHELP_DEFAULTS_APP_LAUNCH_COUNT];
    for (NSString *key in dataToRemove) [self.secureStore removeObjectWithKey:key];

    [self.database deleteAllTickets];
}

-(void)clearCustomData{
    [[FDCustomData sharedInstance]clearCustomData];
}

-(void)clearBreadcrumbs{
    [[FDBreadCrumb sharedInstance]clearBreadCrumbs];
}

/* Custom data & bread crumbs must be cleared using its built in clear methods */
-(void)clearEverything{
    [self.database deleteEverything];
    [[FDCustomData sharedInstance]clearCustomData];
    [[FDBreadCrumb sharedInstance]clearBreadCrumbs];
    [self.secureStore clearStoreData];
}

@end