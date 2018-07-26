//
//  HLFAQUtil.h
//  HotlineSDK
//
//  Created by Hrishikesh on 06/06/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//
#ifndef HLFAQUtil_h
#define HLFAQUtil_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FCArticles.h"
#import "FCArticleContent.h"
#import "FCArticleDetailViewController.h"

@interface FCFAQUtil : NSObject

+(void) launchArticleID:(NSNumber *) articleId withNavigationCtlr:(UIViewController *) controller andFaqOptions:(FAQOptions *)faqOptions;
+(void) launchArticle:(FCArticles *) article withNavigationCtlr:(UIViewController *) controller andFaqOptions:(FAQOptions *)faqOptions;
+(FCArticleDetailViewController *) getArticleDetailController:(FCArticles *) article;
+(void) setFAQOptions:(FAQOptions*) options onController:(FCViewController *)controller;
+(BOOL) hasTags:(FAQOptions *) options;
+(BOOL) hasContactUsTags:(FAQOptions *) options;
+(BOOL) hasFilteredViewTitle:(FAQOptions *) options;
+(FAQOptions *) nonTagCopy:(FAQOptions *)options;
@end

#endif /* HLFAQUtil_h */
