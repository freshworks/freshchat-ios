//
//  HLArticleDetailViewController.h
//  HotlineSDK
//
//  Created by kirthikas on 21/09/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDYesNoPromptView.h"
#import "FDAlertView.h"
#import "HLViewController.h"
#import "FAQOptionsInterface.h"

//Implement FDYesNoPromptViewDelegate if needed
@interface HLArticleDetailViewController : HLViewController <UIWebViewDelegate, UIScrollViewDelegate, HLYesNoPromptViewDelegate, FDAlertViewDelegate, FAQOptionsInterface>

@property (strong, nonatomic) NSString *articleDescription;
@property (strong, nonatomic) NSNumber *articleID;
@property (strong, nonatomic) NSString *categoryTitle;
@property (strong,nonatomic) NSString *articleTitle;
@property (strong,nonatomic) NSNumber *categoryID;
@property (nonatomic, assign) BOOL isFromSearchView;

@end
