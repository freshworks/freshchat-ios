//
//  HLViewRedirector.m
//  HotlineSDK
//
//  Created by user on 16/01/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "HLInterstitialViewController.h"
#import "HLTagManager.h"
#import "HLViewController.h"
#import "HLContainerController.h"
#import "FDMessageController.h"
#import "HLCategoryListController.h"
#import "HLCategoryGridViewController.h"
#import "HLFAQUtil.h"
#import "HLChannelViewController.h"
#import "HLArticlesController.h"
#import "HLFAQUtil.h"
#import "HLConversationUtil.h"
#import "FDBarButtonItem.h"
#import "HLControllerUtils.h"
#import "HLLoadingViewBehaviour.h"
#import "HLLocalization.h"
#import "FDUtilities.h"
#import "FDAutolayoutHelper.h"

@interface HLInterstitialViewController() <HLLoadingViewBehaviourDelegate>{
    int footerViewHeight;
}

@property (nonatomic, strong) FreshchatOptions *options;
@property (nonatomic, assign) BOOL isEmbedView;
@property (nonatomic) BOOL restoring;
@property (nonatomic, strong) HLLoadingViewBehaviour *loadingViewBehaviour;

@end

@implementation HLInterstitialViewController

-(instancetype) initViewControllerWithOptions:(FreshchatOptions *) options andIsEmbed:(BOOL) isEmbed{
    self = [super init];
    if (self) {
        self.options = options;
        self.isEmbedView = isEmbed;
        self.restoring = [self.options isKindOfClass:[ConversationOptions class]] ? [FreshchatUser sharedInstance].isRestoring : false;
    }
    return self;
}

-(HLLoadingViewBehaviour*)loadingViewBehaviour {
    if(_loadingViewBehaviour == nil){
        enum SupportType type = [self.options isKindOfClass:[ConversationOptions class]] ? 2 : 1;
        _loadingViewBehaviour = [[HLLoadingViewBehaviour alloc] initWithViewController:self withType:type];
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
    if([FDUtilities isAccountDeleted]){
        return HLLocalizedString(LOC_ERROR_MESSAGE_ACCOUNT_NOT_ACTIVE_TEXT);
    }
    else if(self.restoring) {
        return HLLocalizedString(LOC_RESTORING_CHANNEL_TEXT);
    }
    else if([self.options isKindOfClass:[FAQOptions class]]){
        return HLLocalizedString(LOC_LOADING_FAQ_TEXT);
    }
    else if([self.options isKindOfClass:[ConversationOptions class]]){
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
    self.restoring = [self.options isKindOfClass:[ConversationOptions class]] ? [FreshchatUser sharedInstance].isRestoring : false;
    if(!self.restoring) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self prepareController];
        });
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.barTintColor = [[FCTheme sharedInstance ]navigationBarBackgroundColor];
    self.view.backgroundColor = ([self.options isKindOfClass:[ConversationOptions class]]) ? [[FCTheme sharedInstance] channelListBackgroundColor] : [[FCTheme sharedInstance] faqCategoryBackgroundColor] ;
    [self setNavigationItem];
}

-(void)setFooterView {
    FCFooterView *footerView = [[FCFooterView alloc] initFooterViewWithEmbedded:self.isEmbedView];
    footerView.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:footerView];
    [footerView setViewColor:self.view.backgroundColor];
    footerViewHeight = 20;
    if([FDUtilities isIPhoneXView] && !self.isEmbedView){
        footerViewHeight = 33;
    }
    if([FDUtilities isPoweredByFooterViewHidden] && ![FDUtilities isIPhoneXView]){
        footerViewHeight = 0;
    }
    NSDictionary *views = @{@"footerView" : footerView};    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[footerView(%d)]|",footerViewHeight]  options:0 metrics:nil views:views]];
    [FDAutolayoutHelper centerX:footerView onView:self.view];
}

-(void)viewWillDisappear:(BOOL)animated{
    [self.loadingViewBehaviour unload];
    [self localNotificationUnSubscription];
}

-(void)prepareController{
    if([self.options isKindOfClass:[FAQOptions class]]){
        self.view.backgroundColor = [[FCTheme sharedInstance] faqCategoryBackgroundColor];
        [self handleFAQs:self withOptions:(FAQOptions *)self.options andEmbed:self.isEmbedView];
    }
    else if([self.options isKindOfClass:[ConversationOptions class]]){
        self.view.backgroundColor = [[FCTheme sharedInstance] channelListBackgroundColor];
        if([HLConversationUtil hasTags:(ConversationOptions *)self.options]){
            [self handleConversations:self withOptions:(ConversationOptions *)self.options andEmbed:self.isEmbedView];
        }
        else{
            [self handleConversations:self andEmbed:self.isEmbedView];
        }
    }
    //[self setFooterView];
}

-(void) handleFAQs:(UIViewController *)controller withOptions:(FAQOptions *)options andEmbed : (BOOL)isEmbed {
    [self selectFAQController:options withCompletion:^(HLViewController *preferredController) {
        HLContainerController *containerController = [[HLContainerController alloc]initWithController:preferredController andEmbed:isEmbed];
        [self resetNavigationStackWithController:containerController];
    }];
}

-(void) selectFAQController:(FAQOptions *)options withCompletion : (void (^)(HLViewController *))completion{
    NSManagedObjectContext *ctx = [KonotorDataManager sharedInstance].mainObjectContext;
    if([HLFAQUtil hasTags:options]){
        if(options.filteredType == CATEGORY){
            [[HLTagManager sharedInstance] getCategoriesForTags:[options tags]
                                                      inContext:ctx withCompletion:^(NSArray<HLCategory *> *categories) {
                                                          if(categories && categories.count > 0){
                                                              completion([HLControllerUtils getCategoryController:options]);
                                                          }
                                                          else {
                                                              [options filterContactUsByTags:@[] withTitle:@""];
                                                              completion([HLControllerUtils getCategoryController:options]);
                                                          }
                                                      }];
        }
        else if(options.filteredType == ARTICLE){
            [[HLTagManager sharedInstance] getArticlesForTags:[options tags]
                                                    inContext:ctx
                                               withCompletion:^(NSArray <HLArticle *> *articles) {
                                                   __block HLViewController *preferedController = nil;
                                                   if([articles count] > 1 ){
                                                       preferedController = [[HLArticlesController alloc]init];
                                                       [HLFAQUtil setFAQOptions:options onController:preferedController];
                                                       completion(preferedController);
                                                   } else if([articles count] == 1 ) {
                                                       NSManagedObjectContext *mContext = [KonotorDataManager sharedInstance].mainObjectContext;
                                                       [mContext performBlock:^{
                                                           HLArticle *article = [HLArticle getWithID:[[articles firstObject] articleID] inContext:mContext];
                                                           if(article){
                                                               preferedController = [HLFAQUtil getArticleDetailController:article];
                                                               [HLFAQUtil setFAQOptions:options onController:preferedController];
                                                           }
                                                           else {
                                                               preferedController = [HLControllerUtils getCategoryController:options];
                                                           }
                                                           completion(preferedController);
                                                       }];
                                                   } else {
                                                       // No Matching tags so no need to pass it around
                                                       [options filterByTags:@[] withTitle:@"" andType:0];
                                                       completion([HLControllerUtils getCategoryController:options]);
                                                   }
                                               }];
        }
    }
    else {
        completion([HLControllerUtils getCategoryController:options]);
    }
    
}

-(void) handleConversations:(UIViewController *)controller andEmbed:(BOOL) isEmbed{
    [[KonotorDataManager sharedInstance] fetchAllVisibleChannelsWithCompletion:^(NSArray *channelInfos, NSError *error) {
        HLContainerController *preferredController = nil;
        if (!error) {
            if (channelInfos.count == 1) {
                HLChannelInfo *channelInfo = [channelInfos firstObject];
                FDMessageController *messageController = [[FDMessageController alloc]initWithChannelID:channelInfo.channelID
                                                                                     andPresentModally:YES];
                preferredController = [[HLContainerController alloc]initWithController:messageController andEmbed:isEmbed];
            }
        }
        //default with or without error
        if(!preferredController) {
            HLChannelViewController *channelViewController = [[HLChannelViewController alloc]init];
            [channelViewController setConversationOptions:self.options];
            preferredController = [[HLContainerController alloc]initWithController:channelViewController andEmbed:isEmbed];
        }
        
        [self resetNavigationStackWithController:preferredController];
    }];
}

-(void) handleConversations:(UIViewController *)controller
               withOptions :(ConversationOptions *)options
                   andEmbed:(BOOL) isEmbed {
    if(options.tags.count > 0){
        [self selectConversationController:options withCompletion:^(HLViewController *preferredController) {
            HLContainerController *containerController = [[HLContainerController alloc]initWithController:preferredController andEmbed:isEmbed];
            [self resetNavigationStackWithController:containerController];
        }];
    }
    else{
        [self handleConversations:controller andEmbed:isEmbed];
    }
}

-(void) selectConversationController:(ConversationOptions *)options withCompletion : (void (^)(HLViewController *))completion{
    [[HLTagManager sharedInstance] getChannelsForTags:[options tags] inContext:[KonotorDataManager sharedInstance].mainObjectContext withCompletion:^(NSArray<HLChannel *> *channels, NSError *error){
        HLViewController *preferedController = nil;
        if([channels count] == 0 ) {
            HLChannel *defaultChannel = [HLChannel getDefaultChannelInContext:[KonotorDataManager sharedInstance].mainObjectContext];
            if(defaultChannel != nil ){
                preferedController = [[FDMessageController alloc]initWithChannelID:defaultChannel.channelID
                                                             andPresentModally:YES];
            }
            else{
                preferedController = [[HLChannelViewController alloc]init];
            }
        }
        else if (channels.count == 1) {
            preferedController = [[FDMessageController alloc]initWithChannelID:[channels firstObject].channelID
                                                             andPresentModally:YES];
        }
        else{
            preferedController = [[HLChannelViewController alloc]init];
        }
        [HLConversationUtil setConversationOptions:options andViewController:preferedController];
        completion(preferedController);
    }];
}

- (void) resetNavigationStackWithController:(UIViewController *)controller{
    NSMutableArray<UIViewController *> *viewControllers = [self.navigationController.viewControllers mutableCopy];
    [viewControllers removeObject:self];
    [viewControllers addObject:controller];
    [self.loadingViewBehaviour unload];
    [self.navigationController setViewControllers:viewControllers animated:NO];
}

-(void)setNavigationItem {
    UIBarButtonItem *closeButton = [[FDBarButtonItem alloc]initWithTitle:HLLocalizedString(LOC_RESTORE_CLOSE_BUTTON_TEXT) style:UIBarButtonItemStylePlain target:self action:@selector(closeButton:)];
    if (!self.isEmbedView) {
        self.navigationItem.leftBarButtonItem = closeButton;
    }
}

-(void)closeButton:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
