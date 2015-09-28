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
#import "HLArticleDetailViewController.h"
#import "HLContainerController.h"

@interface HLArticlesController ()

@property(nonatomic, strong)HLCategory *category;

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
    parent.title = @"Article List";
    [self updateDataSource];
}

-(void)updateDataSource{
    self.dataSource = [NSArray arrayWithArray:[self.category.articles allObjects]];
    [self.tableView reloadData];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = @"HLArticleCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    HLArticle *article = self.dataSource[indexPath.row];
    cell.textLabel.text  = article.title;
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    HLArticle *article = self.dataSource[indexPath.row];
    HLArticleDetailViewController *articleDetailController = [[HLArticleDetailViewController alloc]init];
    articleDetailController.articleDescription = article.articleDescription;
    HLContainerController *container = [[HLContainerController alloc]initWithController:articleDetailController];
    [self.navigationController pushViewController:container animated:YES];
}

@end