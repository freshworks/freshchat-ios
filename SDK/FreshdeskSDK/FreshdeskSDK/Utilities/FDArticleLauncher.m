//
//  FDTagFilter.m
//  FreshdeskSDK
//
//  Created by kirthikas on 30/06/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FDArticleLauncher.h"
#import "FDcoreDataCoordinator.h"
#import "MobiHelpDatabase.h"
#import "FDTag.h"
#import "FDArticleListViewController.h"
#import "FDArticleDetailViewController.h"
#import "FDFolderListViewController.h"
#import "FDNavigationBar.h"

@implementation FDArticleLauncher

+(UIViewController *)filterSolutionsUsing:(NSArray*)tagsArray{
    NSManagedObjectContext *mobihelpContext = [[FDCoreDataCoordinator sharedInstance] mainContext];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:MOBIHELP_DB_TAG_ENTITY];
    request.predicate = [NSPredicate predicateWithFormat:@"tagName IN %@",tagsArray];
    NSArray* results = [mobihelpContext executeFetchRequest:request error:nil];
    NSInteger tagCount = [results count];
    if(tagCount)
    {
        if (tagCount == 1) {
            FDTag *tag = [results firstObject];
            FDArticle *article = [FDArticle getArticleWithID:tag.itemID inManagedObjectContext:mobihelpContext];
            FDArticleDetailViewController *articleDetailViewController = [[FDArticleDetailViewController alloc] initWithModalPresentationType:YES];
            articleDetailViewController.articleDescription = article.articleDescription;
            return articleDetailViewController;
        }
        else{
            FDArticleListViewController *articleListViewController = [[FDArticleListViewController alloc]initWithModalPresentationType:YES];
            articleListViewController.tagsArray = tagsArray;
            return articleListViewController;
        }
    }
    else{
        FDFolderListViewController *folderListViewController = [[FDFolderListViewController alloc]init];
        return folderListViewController;
    }
}

@end
