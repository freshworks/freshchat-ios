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
#import "FDArticleContent.h"
#import "HLArticleDetailViewController.h"

@interface HLArticleUtil : NSObject

+(void) launchArticleID:(NSNumber *) articleId withNavigationCtlr:(UIViewController *) controller andFAQOptions:(FAQOptions *)faqOptions;
+(void) launchArticle:(HLArticle *) article withNavigationCtlr:(UIViewController *) controller andFAQOptions:(FAQOptions *)faqOptions;
+(HLArticleDetailViewController *) getArticleDetailController:(HLArticle *) article;
+(void) setFAQOptions:(FAQOptions*) options andViewController: (HLViewController *) viewController;
+ (void) addFaqOpenArticleEvent :(HLArticle *) article;
+ (void) addFaqOpenSearchArticleEvent:(FDArticleContent *)article;
@end

#endif /* ArticleUtil_h */
