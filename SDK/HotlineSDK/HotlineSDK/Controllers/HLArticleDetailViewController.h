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

//Implement FDYesNoPromptViewDelegate if needed
@interface HLArticleDetailViewController : UIViewController <UIWebViewDelegate, UIScrollViewDelegate, FDYesNoPromptViewDelegate, FDAlertViewDelegate>

@property (strong, nonatomic) NSString *articleDescription;
@property (strong, nonatomic) NSNumber *articleID;
@property (strong, nonatomic) NSString *categoryTitle;
@property (strong,nonatomic) NSNumber *categoryID;

@end
