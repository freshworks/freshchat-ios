//
//  ArticleUtil.m
//  HotlineSDK
//
//  Created by Hrishikesh on 06/06/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCFAQUtil.h"
#import "FCArticleDetailViewController.h"
#import "FCCategories.h"
#import "FCDataManager.h"
#import "FCContainerController.h"

@implementation FCFAQUtil

+(void) launchArticleID:(NSNumber *) articleId
     withNavigationCtlr:(id) controller
          andFaqOptions:(FAQOptions *)faqOptions
            fromLink:(BOOL)fromLink {
    NSManagedObjectContext *mContext = [FCDataManager sharedInstance].mainObjectContext;
    [mContext performBlock:^{
        FCArticles *article = [FCArticles getWithID:articleId inContext:mContext];
        if(article){
            [FCFAQUtil launchArticle:article withNavigationCtlr:controller andFaqOptions:faqOptions fromLink:fromLink];
        }
    }];
}

+(void) launchArticle:(FCArticles *) article
        withNavigationCtlr:(id) controller
           andFaqOptions:(FAQOptions *)faqOptions
             fromLink: (BOOL) fromLink {
    dispatch_async(dispatch_get_main_queue(),^{
        UIViewController *viewController = nil;
        UINavigationController *navigationController = nil;
        FCArticleDetailViewController *articleDetailController = [self getArticleDetailController:article];
        if(fromLink) {
            articleDetailController.isFilteredView = YES;
        } else {
            [FCFAQUtil setFAQOptions:faqOptions onController:articleDetailController];
        }
        if([controller isKindOfClass:[UIViewController class]]) {
            viewController = (UIViewController *) controller;
            navigationController = viewController.navigationController;
        } else if([controller isKindOfClass:[UINavigationController class]]) {
            navigationController = (UINavigationController *) controller;
        }
        FCContainerController *container = [[FCContainerController alloc]initWithController:articleDetailController andEmbed:NO];
        if (navigationController) {
            [navigationController pushViewController:container animated:YES];
        } else {
            articleDetailController.showCloseButton = YES;
            UINavigationController *navController = [[UINavigationController alloc]     initWithRootViewController:container];
            [viewController presentViewController:navController animated:YES completion:nil];
        }
    });
}

+(FCArticleDetailViewController *) getArticleDetailController:(FCArticles *) article{
    FCArticleDetailViewController* articleDetailController=[[FCArticleDetailViewController alloc] init];
    articleDetailController.articleID = article.articleID;
    articleDetailController.articleTitle = article.title;
    articleDetailController.articleDescription = article.articleDescription;
    articleDetailController.categoryTitle=article.category.title;
    articleDetailController.categoryID = article.categoryID;
    return articleDetailController;
}

+(void)setFAQOptions:(FAQOptions*) options onController:(FCViewController *)controller{
    if ([controller conformsToProtocol:@protocol(FAQOptionsInterface)]){
        FCViewController <FAQOptionsInterface> *vc
        = (FCViewController <FAQOptionsInterface> *) controller;
        [vc setFAQOptions:options];
    }
}

+(BOOL) hasTags:(FAQOptions *) options{
    if(options){
        return options.tags && options.tags.count > 0;
    }
    return NO;
}


+(BOOL) hasContactUsTags:(FAQOptions *) options{
    if(options){
        return options.contactUsTags && options.contactUsTags.count > 0;
    }
    return NO;
}

+(BOOL) hasFilteredViewTitle:(FAQOptions *) options{
    if(options){
        return options.filteredViewTitle && options.filteredViewTitle.length > 0;
    }
    return NO;
}

+(FAQOptions *)copyFaqOptions:(FAQOptions *) options
                      includeTags:(BOOL) includeTags {
    FAQOptions *copy = [FAQOptions new];
    if(copy){
        copy.showContactUsOnAppBar = options.showContactUsOnAppBar;
        copy.showFaqCategoriesAsGrid = options.showFaqCategoriesAsGrid;
        copy.showContactUsOnFaqScreens = options.showContactUsOnFaqScreens;
        [copy filterContactUsByTags:options.contactUsTags withTitle:options.contactUsTitle];
        if(includeTags){
            [copy filterByTags:options.tags
                     withTitle:options.filteredViewTitle
                       andType:options.filteredType];
        }
    }
    return copy;
}

+(FAQOptions *) nonTagCopy:(FAQOptions *)options{
    return [self copyFaqOptions:options includeTags:false];
}

@end
