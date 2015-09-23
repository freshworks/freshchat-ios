//
//  HLArticleDetailViewController.h
//  HotlineSDK
//
//  Created by kirthikas on 21/09/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "FDYesNoPromptView.h"

//Implement FDYesNoPromptViewDelegate if needed
@interface HLArticleDetailViewController : UIViewController <UIWebViewDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) NSString *articleDescription;
@property (strong, nonatomic) NSNumber *articleID;

@end
