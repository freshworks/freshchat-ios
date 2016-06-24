//
//  ArticleUtil.h
//  HotlineSDK
//
//  Created by Hrishikesh on 06/06/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//
#ifndef ArticleUtil_h
#define ArticleUtil_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HLArticle.h"
#import "HLArticleDetailViewController.h"

@interface HLArticleUtil : NSObject

+(void) launchArticleID:(NSNumber *) articleId withNavigationCtlr:(UIViewController *) controller;
+(void) launchArticle:(HLArticle *) article withNavigationCtlr:(UIViewController *) controller;
+(HLArticleDetailViewController *) getArticleDetailController:(HLArticle *) article;

@end

#endif /* ArticleUtil_h */
