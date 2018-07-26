//
//  FDArticleContent.m
//  FreshdeskSDK
//
//  Created by kirthikas on 11/06/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FCArticleContent.h"


@implementation FCArticleContent

-(id)initWithArticle:(FCArticles *)article{
    FCArticleContent *articleContent = [[FCArticleContent alloc]init];
    articleContent.articleID = article.articleID;
    articleContent.articleDescription = article.articleDescription;
    articleContent.title = article.title;
    articleContent.categoryName = article.category.title;
    articleContent.categoryID = article.categoryID;
    return articleContent;
}

@end
