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
#import "HLContainerController.h"
#import "KonotorDataManager.h"
#import "FDBarButtonItem.h"
#import "FDArticleListCell.h"
#import "HLArticleUtil.h"

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
    self.tableView.separatorColor = [[HLTheme sharedInstance] tableViewCellSeparatorColor];
    if([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]){
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    parent.navigationItem.title = self.category.title;
    [self setNavigationItem];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self updateDataSource];
}

-(void)updateDataSource{
    self.articles = self.category.articles.allObjects;
    [self.tableView reloadData];
    [[KonotorDataManager sharedInstance]fetchAllArticlesOfCategoryID:self.category.categoryID handler:^(NSArray *articles, NSError *error) {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"position" ascending: YES];
        NSArray *sortedArticles = [[self.category.articles allObjects] sortedArrayUsingDescriptors:@[sortDescriptor]];
        self.articles = sortedArticles;
        [self.tableView reloadData];
    }];
}

-(void)setNavigationItem{
    UIBarButtonItem *searchBarButton = [[FDBarButtonItem alloc] initWithImage:[self.theme getImageWithKey:IMAGE_SEARCH_ICON]
                                                                        style:UIBarButtonItemStylePlain target:self action:@selector(searchButtonAction:)];
    [self configureBackButtonWithGestureDelegate:self];
    self.parentViewController.navigationItem.rightBarButtonItems = @[searchBarButton];
}

-(void)searchButtonAction:(id)sender{
    HLSearchViewController *searchViewController = [[HLSearchViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc]initWithRootViewController:searchViewController];
    [navController setModalPresentationStyle:UIModalPresentationCustom];
    [self presentViewController:navController animated:NO completion:nil];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = @"HLArticleCell";
    
    FDArticleListCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (!cell) {
        cell = [[FDArticleListCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    if (indexPath.row < self.articles.count) {
        HLArticle *article = self.articles[indexPath.row];
        cell.articleText.text = article.title;
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell     forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if ([tableView respondsToSelector:@selector(setSeparatorInset:)])
    {
        [tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([tableView respondsToSelector:@selector(setLayoutMargins:)])
    {
        [tableView setLayoutMargins:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)])
    {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)sectionIndex{
    return self.articles.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UIFont *cellFont = [self.theme articleListFont];
    CGFloat heightOfcell = [HLListViewController heightOfCell:cellFont];
    return heightOfcell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row < self.articles.count) {
        HLArticle *article = self.articles[indexPath.row];
        [HLArticleUtil launchArticle:article withNavigationCtlr:self.navigationController];
    }
}

@end