//
//  HLViewRedirector.m
//  HotlineSDK
//
//  Created by user on 16/01/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCInterstitialViewController.h"
#import "FCTagManager.h"
#import "FCViewController.h"
#import "FCContainerController.h"
#import "FCMessageController.h"
#import "FCCategoryListController.h"
#import "FCCategoryGridViewController.h"
#import "FCFAQUtil.h"
#import "FCChannelViewController.h"
#import "FCArticlesController.h"
#import "FCFAQUtil.h"
#import "FCConversationUtil.h"
#import "FCBarButtonItem.h"
#import "FCControllerUtils.h"
#import "FCLoadingViewBehaviour.h"
#import "FCLocalization.h"
#import "FCUtilities.h"
#import "FCAutolayoutHelper.h"

@interface ConversationOptions()

@property (nonatomic, strong) NSNumber *channelID;

@end


@interface FCInterstitialViewController() <HLLoadingViewBehaviourDelegate>{
    int footerViewHeight;
}

@property (nonatomic, strong) FreshchatOptions *freshchatOptions;
@property (nonatomic, assign) BOOL isEmbedView;
@property (nonatomic) BOOL restoring;
@property (nonatomic, strong) FCLoadingViewBehaviour *loadingViewBehaviour;

@end

@implementation FCInterstitialViewController

-(instancetype) initViewControllerWithOptions:(FreshchatOptions *) options andIsEmbed:(BOOL) isEmbed{
    self = [super init];
    if (self) {
        self.freshchatOptions = options;
        self.isEmbedView = isEmbed;
        self.restoring = [self.freshchatOptions isKindOfClass:[ConversationOptions class]] ? [FreshchatUser sharedInstance].isRestoring : false;
    }
    return self;
}

-(FCLoadingViewBehaviour*)loadingViewBehaviour {
    if(_loadingViewBehaviour == nil){
        enum SupportType type = [self.freshchatOptions isKindOfClass:[ConversationOptions class]] ? 2 : 1;
        _loadingViewBehaviour = [[FCLoadingViewBehaviour alloc] initWithViewController:self withType:type];
    }
    return _loadingViewBehaviour;
}

-(UIView *)contentDisplayView{
    return self.view;
}

-(NSString *)emptyText{
    return HLLocalizedString(LOC_EMPTY_FAQ_TEXT);
}

-(NSString *)loadingText{
    if([FCUtilities isAccountDeleted]){
        return HLLocalizedString(LOC_ERROR_MESSAGE_ACCOUNT_NOT_ACTIVE_TEXT);
    }
    else if(self.restoring) {
        return HLLocalizedString(LOC_RESTORING_CHANNEL_TEXT);
    }
    else if([self.freshchatOptions isKindOfClass:[FAQOptions class]]){
        return HLLocalizedString(LOC_LOADING_FAQ_TEXT);
    }
    else if([self.freshchatOptions isKindOfClass:[ConversationOptions class]]){
        return HLLocalizedString(LOC_LOADING_CHANNEL_TEXT);
    }
    return 0;
}

-(void)localNotificationSubscription{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreStateChanged:)
                                                 name:FRESHCHAT_USER_RESTORE_STATE object:nil];
}


-(void)restoreStateChanged:(NSNotification *)notification {
    if(self.restoring && [notification.userInfo[@"state"] intValue] == 1) {
        [self checkRestoreStateChanged];
    }
}

-(void)localNotificationUnSubscription{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FRESHCHAT_USER_RESTORE_STATE object:nil];
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.loadingViewBehaviour load:0];
    [self localNotificationSubscription];
    [self checkRestoreStateChanged];
}

-(void) checkRestoreStateChanged {
    self.restoring = [self.freshchatOptions isKindOfClass:[ConversationOptions class]] ? [FreshchatUser sharedInstance].isRestoring : false;
    if(!self.restoring) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self prepareController];
        });
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.barTintColor = [[FCTheme sharedInstance ]navigationBarBackgroundColor];
    self.view.backgroundColor = ([self.freshchatOptions isKindOfClass:[ConversationOptions class]]) ? [[FCTheme sharedInstance] channelListBackgroundColor] : [[FCTheme sharedInstance] faqCategoryBackgroundColor] ;
    [self setNavigationItem];
}

-(void)setFooterView {
    FCFooterView *footerView = [[FCFooterView alloc] initFooterViewWithEmbedded:self.isEmbedView];
    footerView.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:footerView];
    [footerView setViewColor:self.view.backgroundColor];
    footerViewHeight = 20;
    if([FCUtilities hasNotchDisplay] && !self.isEmbedView) {
        footerViewHeight = 33;
    }
    if([FCUtilities isPoweredByFooterViewHidden] && ![FCUtilities hasNotchDisplay]) {
        footerViewHeight = 0;
    }
    NSDictionary *views = @{@"footerView" : footerView};    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[footerView(%d)]|",footerViewHeight]  options:0 metrics:nil views:views]];
    [FCAutolayoutHelper centerX:footerView onView:self.view];
}

-(void)viewWillDisappear:(BOOL)animated{
    [self.loadingViewBehaviour unload];
    [self localNotificationUnSubscription];
}

-(void)prepareController{
    if([self.freshchatOptions isKindOfClass:[FAQOptions class]]){
        self.view.backgroundColor = [[FCTheme sharedInstance] faqCategoryBackgroundColor];
        [self handleFAQs:self withOptions:(FAQOptions *)self.freshchatOptions andEmbed:self.isEmbedView];
    }
    else if([self.freshchatOptions isKindOfClass:[ConversationOptions class]]){
        self.view.backgroundColor = [[FCTheme sharedInstance] channelListBackgroundColor];
        [self handleConversations:self withOptions:(ConversationOptions *)self.freshchatOptions andEmbed:self.isEmbedView];
    }
    //[self setFooterView];
}

-(void) handleFAQs:(UIViewController *)controller withOptions:(FAQOptions *)options andEmbed : (BOOL)isEmbed {
    [self selectFAQController:options withCompletion:^(FCViewController *preferredController) {
        FCContainerController *containerController = [[FCContainerController alloc]initWithController:preferredController andEmbed:isEmbed];
        [self resetNavigationStackWithController:containerController];
    }];
}

-(void) selectFAQController:(FAQOptions *)options withCompletion : (void (^)(FCViewController *))completion{
    NSManagedObjectContext *ctx = [FCDataManager sharedInstance].mainObjectContext;
    if([FCFAQUtil hasTags:options]){
        if(options.filteredType == CATEGORY){
            [[FCTagManager sharedInstance] getCategoriesForTags:[options tags]
                                                      inContext:ctx withCompletion:^(NSArray<FCCategories *> *categories) {
                                                          if(categories && categories.count > 0){
                                                              completion([FCControllerUtils getCategoryController:options]);
                                                          }
                                                          else {
                                                              [options filterContactUsByTags:options.tags withTitle:@""];
                                                              completion([FCControllerUtils getCategoryController:options]);
                                                          }
                                                      }];
        }
        else if(options.filteredType == ARTICLE){
            [[FCTagManager sharedInstance] getArticlesForTags:[options tags]
                                                    inContext:ctx
                                               withCompletion:^(NSArray <FCArticles *> *articles) {
                                                   __block FCViewController *preferedController = nil;
                                                   if([articles count] > 1 ){
                                                       preferedController = [[FCArticlesController alloc]init];
                                                       [FCFAQUtil setFAQOptions:options onController:preferedController];
                                                       completion(preferedController);
                                                   } else if([articles count] == 1 ) {
                                                       NSManagedObjectContext *mContext = [FCDataManager sharedInstance].mainObjectContext;
                                                       [mContext performBlock:^{
                                                           FCArticles *article = [FCArticles getWithID:[[articles firstObject] articleID] inContext:mContext];
                                                           if(article){
                                                               preferedController = [FCFAQUtil getArticleDetailController:article];
                                                               [FCFAQUtil setFAQOptions:options onController:preferedController];
                                                           }
                                                           else {
                                                               preferedController = [FCControllerUtils getCategoryController:options];
                                                           }
                                                           completion(preferedController);
                                                       }];
                                                   } else {
                                                       // No Matching tags so no need to pass it around
                                                       [options filterByTags:options.tags withTitle:@"" andType:0];
                                                       completion([FCControllerUtils getCategoryController:options]);
                                                   }
                                               }];
        }
    }
    else {
        completion([FCControllerUtils getCategoryController:options]);
    }
    
}

-(void) handleConversations:(UIViewController *)controller andEmbed:(BOOL) isEmbed{
    [[FCDataManager sharedInstance] fetchAllVisibleChannelsWithCompletion:^(NSArray *channelInfos, NSError *error) {
        FCContainerController *preferredController = nil;
        if (!error) {
            if (channelInfos.count == 1) {
                FCChannelInfo *channelInfo = [channelInfos firstObject];
                FCMessageController *messageController = [[FCMessageController alloc]initWithChannelID:channelInfo.channelID
                                                                                     andPresentModally:YES];
                preferredController = [[FCContainerController alloc]initWithController:messageController andEmbed:isEmbed];
            }
        }
        //default with or without error
        if(!preferredController) {
            FCChannelViewController *channelViewController = [[FCChannelViewController alloc]init];
            [channelViewController setConversationOptions:self.freshchatOptions];
            preferredController = [[FCContainerController alloc]initWithController:channelViewController andEmbed:isEmbed];
        }
        
        [self resetNavigationStackWithController:preferredController];
    }];
}

-(void) handleConversations:(UIViewController *)controller
               withOptions :(ConversationOptions *)options
                   andEmbed:(BOOL) isEmbed {
    if(options.tags.count > 0 || options.channelID != nil ){
        [self selectConversationController:options withCompletion:^(FCViewController *preferredController) {
            FCContainerController *containerController = [[FCContainerController alloc]initWithController:preferredController andEmbed:isEmbed];
            [self resetNavigationStackWithController:containerController];
        }];
    }
    else{
        [self handleConversations:controller andEmbed:isEmbed];
    }
}

-(void) selectConversationController:(ConversationOptions *)options withCompletion : (void (^)(FCViewController *))completion{
    if(options.tags.count > 0) {
        [[FCTagManager sharedInstance] getChannelsForTags:[options tags] inContext:[FCDataManager sharedInstance].mainObjectContext withCompletion:^(NSArray<FCChannels *> *channels, NSError *error){
            [self processSelectConversationController:options channels:channels error:error withCompletion:completion];
        }];
    } else if (options.channelID != nil) {
        [[FCTagManager sharedInstance] getChannel:nil channelIds:@[options.channelID] inContext:[FCDataManager sharedInstance].mainObjectContext withCompletion:^(NSArray<FCChannels *> *channels, NSError *error){
            [self processSelectConversationController:options channels:channels error:error withCompletion:completion];
        }];
    }
}

-(void) processSelectConversationController:(ConversationOptions *)options channels:(NSArray<FCChannels *>*) channels error:(NSError *) error withCompletion : (void (^)(FCViewController *))completion {
        FCViewController *preferedController = nil;
        if([channels count] == 0 ) {
            FCChannels *defaultChannel = [FCChannels getDefaultChannelInContext:[FCDataManager sharedInstance].mainObjectContext];
            if(defaultChannel != nil ){
                preferedController = [[FCMessageController alloc]initWithChannelID:defaultChannel.channelID
                                                                 andPresentModally:YES];
            }
            else{
                preferedController = [[FCChannelViewController alloc]init];
            }
        }
        else if (channels.count == 1) {
            preferedController = [[FCMessageController alloc]initWithChannelID:[channels firstObject].channelID
                                                             andPresentModally:YES];
        }
        else{
            preferedController = [[FCChannelViewController alloc]init];
        }
        [FCConversationUtil setConversationOptions:options andViewController:preferedController];
        completion(preferedController);
}

- (void) resetNavigationStackWithController:(UIViewController *)controller{
    NSMutableArray<UIViewController *> *viewControllers = [self.navigationController.viewControllers mutableCopy];
    [viewControllers removeObject:self];
    [viewControllers addObject:controller];
    [self.loadingViewBehaviour unload];
    [self.navigationController setViewControllers:viewControllers animated:NO];
}

-(void)setNavigationItem {
    if (!self.isEmbedView) {
        UIImage *closeImage = [[FCTheme sharedInstance] getImageWithKey:IMAGE_SOLUTION_CLOSE_BUTTON];
        FCBarButtonItem *closeButton;
        if (closeImage) {
            closeButton = [FCUtilities getCloseBarBtnItemforCtr:self withSelector:@selector(closeButton:)];
        }
        else {
            closeButton = [[FCBarButtonItem alloc]initWithTitle:HLLocalizedString(LOC_RESTORE_CLOSE_BUTTON_TEXT) style:UIBarButtonItemStylePlain target:self action:@selector(closeButton:)];
        }
        self.navigationItem.leftBarButtonItem = closeButton;
    }
}

-(void)closeButton:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
