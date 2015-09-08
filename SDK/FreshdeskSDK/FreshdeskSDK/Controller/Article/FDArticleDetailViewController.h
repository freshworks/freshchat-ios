//
//  FDArticleDetailViewController.h
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 06/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FDArticleDetailViewController : UIViewController <UIWebViewDelegate>

@property (strong, nonatomic) NSString *articleDescription;

- (instancetype)initWithModalPresentationType:(BOOL)isModalPresentation;

@end
