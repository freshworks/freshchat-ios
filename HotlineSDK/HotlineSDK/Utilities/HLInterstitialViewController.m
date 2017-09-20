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
#import "HLControllerUtils.h"
#import "HLLoadingViewBehaviour.h"
#import "HLLocalization.h"

@interface HLInterstitialViewController() <HLLoadingViewBehaviourDelegate>

@property (nonatomic, strong) HotlineOptions *options;
@property (nonatomic, assign) BOOL isEmbedView;
@property (nonatomic, strong) HLLoadingViewBehaviour *loadingViewBehaviour;

@end

@implementation HLInterstitialViewController

-(instancetype) initViewControllerWithOptions:(HotlineOptions *) options andIsEmbed:(BOOL) isEmbed{
    self = [super init];
    if (self) {
        self.options = options;
        self.isEmbedView = isEmbed;
    }
    return self;
}

-(HLLoadingViewBehaviour*)loadingViewBehaviour {
    if(_loadingViewBehaviour == nil){
        _loadingViewBehaviour = [[HLLoadingViewBehaviour alloc] initWithViewController:self];
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
    if([self.options isKindOfClass:[FAQOptions class]]){
        return HLLocalizedString(LOC_LOADING_FAQ_TEXT);
    }
    else if([self.options isKindOfClass:[ConversationOptions class]]){
        return HLLocalizedString(LOC_LOADING_CHANNEL_TEXT);
    }
    return 0;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.loadingViewBehaviour load:0];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self prepareController];
    });
}

-(void)viewWillDisappear:(BOOL)animated{
    [self.loadingViewBehaviour unload];
}

-(void)prepareController{
    if([self.options isKindOfClass:[FAQOptions class]]){
        [self handleFAQs:self withOptions:(FAQOptions *)self.options andEmbed:self.isEmbedView];
    }
    else if([self.options isKindOfClass:[ConversationOptions class]]){
        if([HLConversationUtil hasTags:(ConversationOptions *)self.options]){
            [self handleConversations:self withOptions:(ConversationOptions *)self.options andEmbed:self.isEmbedView];
        }
        else{
            [self handleConversations:self andEmbed:self.isEmbedView];
        }
    }
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
        if(!preferredController){
            HLChannelViewController *channelViewController = [[HLChannelViewController alloc]init];
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
    [[HLTagManager sharedInstance] getChannelsForTags:[options tags] inContext:[KonotorDataManager sharedInstance].mainObjectContext withCompletion:^(NSArray<HLChannel *> *channels){
        HLViewController *preferedController = nil;
        if([channels count] == 0 ){
            HLChannel *defaultChannel = [HLChannel getDefaultChannelInContext:[KonotorDataManager sharedInstance].mainObjectContext];
            preferedController = [[FDMessageController alloc]initWithChannelID:defaultChannel.channelID
                                                             andPresentModally:YES];
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

@end
