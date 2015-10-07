//
//  HLArticlesViewController.m
//  HotlineSDK
//
//  Created by AravinthChandran on 9/9/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "HLArticlesController.h"
#import "WebServices.h"
#import "HLFAQServices.h"
#import "HLArticle.h"
#import "HLMacros.h"
#import "HLTheme.h"
#import "HLArticleDetailViewController.h"
#import "HLContainerController.h"

@interface HLArticlesController ()

@property(nonatomic, strong)HLCategory *category;
@property(nonatomic, strong)NSArray *articles;

@end

@implementation HLArticlesController

-(instancetype)initWithCategory:(HLCategory *)category{
    self = [super init];
    if (self) {
        self.category = category;
    }
    return self;
}

-(void)willMoveToParentViewController:(UIViewController *)parent{
    [super willMoveToParentViewController:parent];
    parent.title = self.category.title;
    [self updateDataSource];
    [self setNavigationItem];
}

-(void)updateDataSource{
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"position" ascending: YES];
    NSArray *sortedArticles = [[self.category.articles allObjects] sortedArrayUsingDescriptors:@[sortDescriptor]];
    self.articles = sortedArticles;
    [self.tableView reloadData];
}

-(void)setNavigationItem{
    UIImage *searchButtonImage = [HLTheme getImageFromMHBundleWithName:HLLocalizedString(@"FAQ_GRID_VIEW_SEARCH_BUTTON_IMAGE")];
    
    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithImage:searchButtonImage style:UIBarButtonItemStylePlain target:self action:@selector(searchButtonAction:)];
    
    self.parentViewController.navigationItem.rightBarButtonItem = searchButton;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = @"HLArticleCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    HLArticle *article = self.articles[indexPath.row];
    cell.textLabel.text  = article.title;
    return cell;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)sectionIndex{
    return self.articles.count;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    HLArticle *article = self.articles[indexPath.row];
    HLArticleDetailViewController *articleDetailController = [[HLArticleDetailViewController alloc]init];
    articleDetailController.articleID = article.articleID;
    articleDetailController.articleDescription = article.articleDescription;
    articleDetailController.categoryTitle = self.category.title;
    HLContainerController *container = [[HLContainerController alloc]initWithController:articleDetailController];
    [self.navigationController pushViewController:container animated:YES];
}

@end