//
//  CategoryViewBehaviour.m
//  HotlineSDK
//
//  Created by Hrishikesh on 11/01/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLCategoryViewBehaviour.h"
#import "HLFAQUtil.h"
#import "HLTagManager.h"
#import "FDSolutionUpdater.h"
#import "FDLocalNotification.h"
#import "HLMacros.h"
#import "FDUtilities.h"
#import "FDBarButtonItem.h"
#import "HLLocalization.h"
#import "HLEventManager.h"
#import "HLSearchViewController.h"
#import "HLControllerUtils.h"

@interface  HLCategoryViewBehaviour ()

@property (nonatomic, strong) UIViewController <HLCategoryViewBehaviourDelegate> *categoryViewDelegate;
@property (nonatomic, strong) FAQOptions *faqOptions;
@property (nonatomic, strong) HLTheme *theme;

@end

@implementation HLCategoryViewBehaviour

-(instancetype) initWithViewController:(UIViewController <HLCategoryViewBehaviourDelegate> *) viewController andFaqOptions:(FAQOptions *) faqOptions{
    self = [super init];
    if(self){
        self.categoryViewDelegate = viewController;
        self.faqOptions = faqOptions;
        self.isFilteredView = [HLFAQUtil hasTags:self.faqOptions];
        self.theme = [HLTheme sharedInstance];
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
        [[HLTagManager sharedInstance] getCategoriesForTags:self.faqOptions.tags
                                                  inContext:[KonotorDataManager sharedInstance].mainObjectContext
                                             withCompletion:^(NSArray<HLCategory *> *categories){
                                                 if (categories.count == 0 ) {
                                                     [[KonotorDataManager sharedInstance] fetchAllCategoriesWithCompletion:^(NSArray *categories, NSError *error) {
                                                         if (!error) {
                                                             self.isFallback = YES;
                                                             [self.categoryViewDelegate onCategoriesUpdated:categories];
                                                         }
                                                     }];
                                                 }
                                                 else {
                                                     [self.categoryViewDelegate onCategoriesUpdated:categories];
                                                 }
                                             }];
    }
    else{
        [[KonotorDataManager sharedInstance] fetchAllCategoriesWithCompletion:^(NSArray *categories, NSError *error) {
            if (!error) {
                [self.categoryViewDelegate onCategoriesUpdated:categories];
            }
        }];
    }
}

-(void)fetchUpdates{
    FDSolutionUpdater *updater = [[FDSolutionUpdater alloc]init];
    [[KonotorDataManager sharedInstance]areSolutionsEmpty:^(BOOL isEmpty) {
        if(isEmpty){
            [updater resetTime];
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
    if([HLFAQUtil hasContactUsTags:self.faqOptions]){
        ConversationOptions *options = [ConversationOptions new];
        [options filterByTags:self.faqOptions.contactUsTags withTitle:self.faqOptions.contactUsTitle];
        [[Hotline sharedInstance] showConversations:self.categoryViewDelegate withOptions:options];
    }
    else{
        [[Hotline sharedInstance] showConversations:self.categoryViewDelegate];
    }
}

-(void)searchButtonAction:(id)sender{
    [[HLEventManager sharedInstance]submitSDKEvent:HLEVENT_FAQ_SEARCH_LAUNCH withBlock:^(HLEvent *event) {
        [event propKey:HLEVENT_PARAM_SOURCE andVal:HLEVENT_SEARCH_LAUNCH_CATEGORY_LIST];
    }];
    HLSearchViewController *searchViewController = [[HLSearchViewController alloc] init];
    [HLFAQUtil setFAQOptions:self.faqOptions andViewController:searchViewController];
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
    
    UIBarButtonItem *contactUsBarButton = [[FDBarButtonItem alloc] initWithImage:[self.theme getImageWithKey:IMAGE_CONTACT_US_ICON]
                                                                           style:UIBarButtonItemStylePlain target:self action:@selector(contactUsButtonAction:)];
    UIBarButtonItem *searchBarButton = [[FDBarButtonItem alloc] initWithImage:[self.theme getImageWithKey:IMAGE_SEARCH_ICON]
                                                                        style:UIBarButtonItemStylePlain target:self action:@selector(searchButtonAction:)];
   
    
    if (![self.categoryViewDelegate isEmbedded]) {
        [HLControllerUtils configureCloseButton:self.categoryViewDelegate forTarget:self
                                       selector:@selector(closeButton:) title:HLLocalizedString(LOC_FAQ_CLOSE_BUTTON_TEXT)];
    }
    else {
        [HLControllerUtils configureBackButtonForController:self.categoryViewDelegate
                                                     withEmbedded:[self.categoryViewDelegate isEmbedded]];
    }
    
    NSMutableArray *rightBarItems = [NSMutableArray new];
    if(!self.isFilteredView || self.isFallback ){
        [rightBarItems addObject:searchBarButton];
    }
    if([HLFAQUtil hasFilteredViewTitle:self.faqOptions]){
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
