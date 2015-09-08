//
//  FDArticleListViewController.h
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 06/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FDArticleListViewController : UIViewController

@property (strong, nonatomic) FDFolder *articleFolder;
@property (strong, nonatomic) NSArray *tagsArray;

- (instancetype)initWithModalPresentationType:(BOOL)isModalPresentation;

@end
