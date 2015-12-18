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
        _theme = [HLTheme sharedInstance];
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
    UIImage *searchButtonImage = [HLTheme getImageFromMHBundleWithName:@"search"];
    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithImage:searchButtonImage style:UIBarButtonItemStylePlain target:self action:@selector(searchButtonAction:)];
    self.parentViewController.navigationItem.rightBarButtonItem = searchButton;
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[[HLTheme sharedInstance] getImageWithKey:@"BackArrow"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self.navigationController
                                                                  action:@selector(popViewControllerAnimated:)];
    self.parentViewController.navigationItem.leftBarButtonItem = backButton;
    
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
        cell.textLabel.text  = article.title;
    }
    return cell;
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)sectionIndex{
    return self.articles.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UIFont *cellFont = [self.theme tableViewCellFont];
    HLArticle *article = self.articles[indexPath.row];
    NSAttributedString *title = [[NSAttributedString alloc] initWithString:article.title attributes:@{NSFontAttributeName:cellFont}];
    CGFloat heightOfcell = [self heightOfcell:title];
    return heightOfcell;
}

- (float) heightOfcell: (NSAttributedString *)title{
    
    CGRect rect = [title boundingRectWithSize:(CGSize){[UIScreen mainScreen].bounds.size.width - 40, CGFLOAT_MAX} options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    CGSize requiredSize = rect.size;
    return requiredSize.height + 36;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
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