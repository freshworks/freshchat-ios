//
//  ArticleUtil.m
//  HotlineSDK
//
//  Created by Hrishikesh on 06/06/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLArticleUtil.h"
#import "HLArticleDetailViewController.h"
#import "HLCategory.h"
#import "KonotorDataManager.h"
#import "HLContainerController.h"
#import "HLEventManager.h"

@implementation HLArticleUtil

+(void) launchArticleID:(NSNumber *) articleId
     withNavigationCtlr:(UIViewController *) controller
          faqOptions:(FAQOptions *)faqOptions andSource : (NSString *)source{
    NSManagedObjectContext *mContext = [KonotorDataManager sharedInstance].mainObjectContext;
    
    [mContext performBlock:^{
        //article search
        HLArticle *article = [HLArticle getWithID:articleId inContext:mContext];
        if(article){
            [HLArticleUtil launchArticle:article withNavigationCtlr:controller faqOptions:faqOptions andSource:source];
        }
    }];
}

+(void) launchArticle:(HLArticle *) article
   withNavigationCtlr:(UINavigationController *) controller
           faqOptions:(FAQOptions *)faqOptions andSource:(NSString *)source;{
    dispatch_async(dispatch_get_main_queue(),^{
        [self addFaqOpenArticleEvent:article andSource:source];
        HLArticleDetailViewController *articleDetailController = [self getArticleDetailController:article];
        [HLArticleUtil setFAQOptions:faqOptions andViewController:articleDetailController];
        HLContainerController *container = [[HLContainerController alloc]initWithController:articleDetailController andEmbed:NO];
        [controller pushViewController:container animated:YES];
    });
}

+ (void) addFaqOpenArticleEvent :(HLArticle *) article andSource :(NSString *) source{
    [[HLEventManager sharedInstance] submitSDKEvent:HLEVENT_FAQ_OPEN_ARTICLE withBlock:^(HLEvent *event) {
        [event propKey:HLEVENT_PARAM_CATEGORY_ID andVal:[article.categoryID stringValue]];
        [event propKey:HLEVENT_PARAM_CATEGORY_NAME andVal:article.category.title];
        [event propKey:HLEVENT_PARAM_ARTICLE_ID andVal:[article.articleID stringValue]];
        [event propKey:HLEVENT_PARAM_ARTICLE_NAME andVal:article.title];
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
@end
