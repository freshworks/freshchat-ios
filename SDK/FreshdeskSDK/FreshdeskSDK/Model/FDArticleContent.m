//
//  FDArticleContent.m
//  FreshdeskSDK
//
//  Created by kirthikas on 11/06/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FDArticleContent.h"


@implementation FDArticleContent

-(id)initWithArticle:(FDArticle *)article{
    FDArticleContent *articleContent = [[FDArticleContent alloc]init];
    articleContent.articleID = article.articleID;
    articleContent.articleDescription = article.articleDescription;
    articleContent.title = article.title;
    return articleContent;
}

@end
