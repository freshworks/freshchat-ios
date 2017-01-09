//
//  ArticleUtil.m
//  HotlineSDK
//
//  Created by Hrishikesh on 06/06/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLFAQUtil.h"
#import "HLArticleDetailViewController.h"
#import "HLCategory.h"
#import "KonotorDataManager.h"
#import "HLContainerController.h"
#import "HLEventManager.h"

@implementation HLFAQUtil

+(void) launchArticleID:(NSNumber *) articleId
     withNavigationCtlr:(UIViewController *) controller
          faqOptions:(FAQOptions *)faqOptions andSource : (NSString *)source{
    NSManagedObjectContext *mContext = [KonotorDataManager sharedInstance].mainObjectContext;
    [mContext performBlock:^{
        HLArticle *article = [HLArticle getWithID:articleId inContext:mContext];
        if(article){
            [HLFAQUtil launchArticle:article withNavigationCtlr:controller faqOptions:faqOptions andSource:source];
        }
    }];
}

+(void) launchArticle:(HLArticle *) article
   withNavigationCtlr:(UINavigationController *) controller
           faqOptions:(FAQOptions *)faqOptions andSource:(NSString *)source;{
    dispatch_async(dispatch_get_main_queue(),^{
        [self addFaqOpenArticleEvent:article andSource:source];
        HLArticleDetailViewController *articleDetailController = [self getArticleDetailController:article];
        [HLFAQUtil setFAQOptions:faqOptions andViewController:articleDetailController];
        HLContainerController *container = [[HLContainerController alloc]initWithController:articleDetailController andEmbed:NO];
        [controller pushViewController:container animated:YES];
    });
}

+ (void) addFaqOpenArticleEvent :(HLArticle *) article andSource :(NSString *) source{
    NSString *categoryName = article.category.title;
    NSString *categoryId = [article.categoryID stringValue];
    NSString *articleId = [article.articleID stringValue];
    NSString *articleName = article.title;
    [[HLEventManager sharedInstance] submitSDKEvent:HLEVENT_FAQ_OPEN_ARTICLE withBlock:^(HLEvent *event) {
        [event propKey:HLEVENT_PARAM_CATEGORY_ID andVal:categoryId];
        [event propKey:HLEVENT_PARAM_CATEGORY_NAME andVal:categoryName];
        [event propKey:HLEVENT_PARAM_ARTICLE_ID andVal:articleId];
        [event propKey:HLEVENT_PARAM_ARTICLE_NAME andVal:articleName];
        [event propKey:HLEVENT_PARAM_SOURCE andVal:source];
    }];
}

+(HLArticleDetailViewController *) getArticleDetailController:(HLArticle *) article{
    HLArticleDetailViewController* articleDetailController=[[HLArticleDetailViewController alloc] init];
    articleDetailController.articleID = article.articleID;
    articleDetailController.articleTitle = article.title;
    articleDetailController.articleDescription = article.articleDescription;
    articleDetailController.categoryTitle=article.category.title;
    articleDetailController.categoryID = article.categoryID;
    return articleDetailController;
}

+(void) setFAQOptions:(FAQOptions*) options andViewController: (HLViewController *) viewController{
    if ([viewController conformsToProtocol:@protocol(FAQOptionsInterface)]){
        HLViewController <FAQOptionsInterface> *vc
        = (HLViewController <FAQOptionsInterface> *) viewController;
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
