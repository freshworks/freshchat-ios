//
//  HLArticlesViewController.m
//  HotlineSDK
//
//  Created by AravinthChandran on 9/9/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "HLArticlesController.h"
#import "HLFAQServices.h"
#import "HLArticle.h"
#import "HLMacros.h"
#import "HLTheme.h"
#import "HLSearchViewController.h"
#import "HLArticleDetailViewController.h"
#import "HLContainerController.h"

@interface HLArticlesController ()

@property(nonatomic, strong)HLCategory *category;
@property(nonatomic, strong)NSArray *articles;
@property (strong, nonatomic) HLTheme *theme;

@end

@implementation HLArticlesController

-(instancetype)initWithCategory:(HLCategory *)category{
    self = [super init];
    if (self) {
        self.category = category;
        self.theme = [HLTheme sharedInstance];
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
    
    UIImage *searchButtonImage = [self.theme getImageWithKey:IMAGE_SEARCH_ICON];
    UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    searchButton.frame = CGRectMake(0, 0, 44, 44);
    [searchButton setImage:searchButtonImage forState:UIControlStateNormal];
    [searchButton addTarget:self action:@selector(searchButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *searchBarButton = [[UIBarButtonItem alloc] initWithCustomView:searchButton];
    [searchBarButton setStyle:UIBarButtonItemStylePlain];
    UIBarButtonItem *fixedItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedItem.width = -20.0f;
    
    //self.parentViewController.navigationItem.rightBarButtonItem = searchBarButton;
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[self.theme getImageWithKey:IMAGE_BACK_BUTTON]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self.navigationController
                                                                  action:@selector(popViewControllerAnimated:)];
    self.parentViewController.navigationItem.leftBarButtonItem = backButton;
    self.parentViewController.navigationItem.rightBarButtonItems = @[fixedItem,searchBarButton];
    /*
     Fix: setting bar button image, disables edge swipe swipe navigation
     http://stackoverflow.com/questions/19054625
     */
    self.parentViewController.navigationController.interactivePopGestureRecognizer.delegate = self;
}

-(void)searchButtonAction:(id)sender{
    HLSearchViewController *searchViewController = [[HLSearchViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc]initWithRootViewController:searchViewController];
    [navController setModalPresentationStyle:UIModalPresentationCustom];
    [self presentViewController:navController animated:NO completion:nil];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = @"HLArticleCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    if (indexPath.row < self.articles.count) {
        HLArticle *article = self.articles[indexPath.row];
        cell.textLabel.numberOfLines = 3;
        cell.textLabel.textColor = [self.theme articleListFontColor];
        cell.textLabel.font = [self.theme articleListFont];
        cell.textLabel.text  = article.title;
    }
    return cell;
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)sectionIndex{
    return self.articles.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    //UIFont *cellFont = [self.theme tableViewCellFont];
    UIFont *cellFont = [self.theme articleListFont];
    HLArticle *searchArticle = self.articles[indexPath.row];
    NSAttributedString *title = [[NSAttributedString alloc] initWithString:searchArticle.title attributes:@{NSFontAttributeName:cellFont}];
    CGFloat heightOfcell = [HLListViewController heightOfCell:title];
    return heightOfcell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row < self.articles.count) {
        HLArticle *article = self.articles[indexPath.row];
        HLArticleDetailViewController *articleDetailController = [[HLArticleDetailViewController alloc]init];
        articleDetailController.articleID = article.articleID;
        articleDetailController.articleTitle = article.title;
        articleDetailController.articleDescription = article.articleDescription;
        articleDetailController.categoryTitle = self.category.title;
        articleDetailController.categoryID = self.category.categoryID;
        HLContainerController *container = [[HLContainerController alloc]initWithController:articleDetailController];
        [self.navigationController pushViewController:container animated:YES];
    }
}

@end