//
//  CategoryViewBehaviour.m
//  HotlineSDK
//
//  Created by Hrishikesh on 11/01/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCCategoryViewBehaviour.h"
#import "FCFAQUtil.h"
#import "FCTagManager.h"
#import "FCSolutionUpdater.h"
#import "FCLocalNotification.h"
#import "FCMacros.h"
#import "FCUtilities.h"
#import "FCBarButtonItem.h"
#import "FCLocalization.h"
#import "FCSearchViewController.h"
#import "FCControllerUtils.h"
#import "FCConstants.h"
#import "FCRemoteConfig.h"

@interface  FCCategoryViewBehaviour ()

@property (nonatomic, weak) UIViewController <HLCategoryViewBehaviourDelegate> *categoryViewDelegate;
@property (nonatomic, strong) FAQOptions *faqOptions;
@property (nonatomic, strong) FCTheme *theme;

@end

@implementation FCCategoryViewBehaviour

-(instancetype) initWithViewController:(UIViewController <HLCategoryViewBehaviourDelegate> *) viewController andFaqOptions:(FAQOptions *) faqOptions{
    self = [super init];
    if(self){
        self.categoryViewDelegate = viewController;
        self.faqOptions = faqOptions;
        self.isFilteredView = [FCFAQUtil hasTags:self.faqOptions];
        self.theme = [FCTheme sharedInstance];
    }
    return self;
}

-(void) load{
    [self loadCategories];
    [self fetchUpdates];
    [self localNotificationSubscription];
}

-(void) unload{
    [self localNotificationUnSubscription];
}

-(void)loadCategories{
    if([self isFilteredView]){
        [[FCTagManager sharedInstance] getCategoriesForTags:self.faqOptions.tags
                                                  inContext:[FCDataManager sharedInstance].mainObjectContext
                                             withCompletion:^(NSArray<FCCategories *> *categories){
                                                 if (categories.count == 0 ) {
                                                     [[FCDataManager sharedInstance] fetchAllCategoriesWithCompletion:^(NSArray *categories, NSError *error) {
                                                         if (!error) {
                                                             self.isFallback = YES;
                                                             [self.categoryViewDelegate onCategoriesUpdated:categories];
                                                         }
                                                     }];
                                                 }
                                                 else {
                                                     self.isFallback = NO;
                                                     [self.categoryViewDelegate onCategoriesUpdated:categories];
                                                 }
                                             }];
    }
    else{
        [[FCDataManager sharedInstance] fetchAllCategoriesWithCompletion:^(NSArray *categories, NSError *error) {
            if (!error) {
                [self.categoryViewDelegate onCategoriesUpdated:categories];
            }
        }];
    }
}

-(void)fetchUpdates{
    FCSolutionUpdater *updater = [[FCSolutionUpdater alloc]init];
    [[FCDataManager sharedInstance]areSolutionsEmpty:^(BOOL isEmpty) {
        if(isEmpty){
            [updater resetTime];
        }
        else {
            //[updater useInterval:SOLUTIONS_FETCH_INTERVAL_ON_SCREEN_LAUNCH];
            FCRefreshIntervals *remoteIntervals = [FCRemoteConfig sharedInstance].refreshIntervals;
            [updater useInterval:remoteIntervals.faqFetchIntervalNormal];
        }
        ShowNetworkActivityIndicator();
        [updater fetchWithCompletion:^(BOOL isFetchPerformed, NSError *error) {
            HideNetworkActivityIndicator();
        }];
    }];
}

-(void)onSolutionsUpdatedInDB{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self loadCategories];
    });
}

-(void)localNotificationUnSubscription{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HOTLINE_SOLUTIONS_UPDATED object:nil];
}

-(void)localNotificationSubscription{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSolutionsUpdatedInDB)
                                                 name:HOTLINE_SOLUTIONS_UPDATED object:nil];
}

-(void) launchConversations {
    if([FCFAQUtil hasContactUsTags:self.faqOptions]){
        ConversationOptions *options = [ConversationOptions new];
        [options filterByTags:self.faqOptions.contactUsTags withTitle:self.faqOptions.contactUsTitle];
        [[Freshchat sharedInstance] showConversations:self.categoryViewDelegate withOptions:options];
    }
    else{
        [[Freshchat sharedInstance] showConversations:self.categoryViewDelegate];
    }
}

-(void)searchButtonAction:(id)sender{
    FCSearchViewController *searchViewController = [[FCSearchViewController alloc] init];
    [FCFAQUtil setFAQOptions:self.faqOptions onController:searchViewController];
    UINavigationController *navController = [[UINavigationController alloc]initWithRootViewController:searchViewController];
    [navController setModalPresentationStyle:UIModalPresentationCustom];
    [self.categoryViewDelegate.navigationController presentViewController:navController animated:NO completion:nil];
}

-(void)contactUsButtonAction:(id)sender{
    [self launchConversations];
}

-(void)closeButton:(id)sender{
    [self.categoryViewDelegate dismissViewControllerAnimated:YES completion:nil];
}

-(void)setNavigationItem{
    
    UIBarButtonItem *contactUsBarButton = [[FCBarButtonItem alloc] initWithImage:[self.theme getImageWithKey:IMAGE_CONTACT_US_ICON]
                                                                           style:UIBarButtonItemStylePlain target:self action:@selector(contactUsButtonAction:)];
    UIBarButtonItem *searchBarButton = [[FCBarButtonItem alloc] initWithImage:[self.theme getImageWithKey:IMAGE_SEARCH_ICON]
                                                                        style:UIBarButtonItemStylePlain target:self action:@selector(searchButtonAction:)];
   
    
    if (![self.categoryViewDelegate isEmbedded]) {
        [FCControllerUtils configureCloseButton:self.categoryViewDelegate forTarget:self
                                       selector:@selector(closeButton:) title:HLLocalizedString(LOC_FAQ_CLOSE_BUTTON_TEXT)];
    }
    else {
        [FCControllerUtils configureBackButtonForController:self.categoryViewDelegate
                                                     withEmbedded:[self.categoryViewDelegate isEmbedded]];
    }
    
    NSMutableArray *rightBarItems = [NSMutableArray new];
    if(!self.isFilteredView || self.isFallback ){
        [rightBarItems addObject:searchBarButton];
    }
    if([FCFAQUtil hasFilteredViewTitle:self.faqOptions] && [FCFAQUtil hasTags:self.faqOptions] && !self.isFallback){
        self.categoryViewDelegate.parentViewController.navigationItem.title = self.faqOptions.filteredViewTitle;
    }
    if(self.faqOptions && self.faqOptions.showContactUsOnAppBar){
        [rightBarItems addObject:contactUsBarButton];
    }
    self.categoryViewDelegate.parentViewController.navigationItem.rightBarButtonItems = rightBarItems;
}

-(BOOL)canDisplayFooterView{
    return self.faqOptions && self.faqOptions.showContactUsOnFaqScreens;
}

@end
