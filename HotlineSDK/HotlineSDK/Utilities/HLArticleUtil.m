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

@implementation HLArticleUtil

+(void) launchArticleID:(NSNumber *) articleId withNavigationCtlr:(UIViewController *) controller{
    NSManagedObjectContext *mContext = [KonotorDataManager sharedInstance].mainObjectContext;
    
    [mContext performBlock:^{
        HLArticle *article = [HLArticle getWithID:articleId inContext:mContext];
        if(article){
            [HLArticleUtil launchArticle:article withNavigationCtlr:controller];
        }
    }];
}

+(void) launchArticle:(HLArticle *) article withNavigationCtlr:(UINavigationController *) controller{
    dispatch_async(dispatch_get_main_queue(),^{
        HLArticleDetailViewController *articleDetailController = [self getArticleDetailController:article];
        HLContainerController *container = [[HLContainerController alloc]initWithController:articleDetailController andEmbed:NO];
        [controller pushViewController:container animated:YES];
    });
}

+(HLArticleDetailViewController *) getArticleDetailController:(HLArticle *) article {
    HLArticleDetailViewController* articleDetailController=[[HLArticleDetailViewController alloc] init];
    articleDetailController.articleID = article.articleID;
    articleDetailController.articleTitle = article.title;
    articleDetailController.articleDescription = article.articleDescription;
    articleDetailController.categoryTitle=article.category.title;
    articleDetailController.categoryID = article.categoryID;
    return articleDetailController;
}

@end