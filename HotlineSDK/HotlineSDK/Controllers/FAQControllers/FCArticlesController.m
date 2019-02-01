//
//  HLArticlesViewController.m
//  HotlineSDK
//
//  Created by AravinthChandran on 9/9/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FCArticlesController.h"
#import "FCFAQServices.h"
#import "FCArticles.h"
#import "FCMacros.h"
#import "FCTheme.h"
#import "FCSearchViewController.h"
#import "FCContainerController.h"
#import "FCDataManager.h"
#import "FCBarButtonItem.h"
#import "FCArticleListCell.h"
#import "FCFAQUtil.h"
#import "FCTagManager.h"
#import "FCLocalization.h"
#import "FCControllerUtils.h"
#import "FCCategoryViewBehaviour.h"

@interface FCArticlesController ()

@property (nonatomic, strong)FCCategories *category;
@property (nonatomic, strong)NSArray *articles;
@property (strong, nonatomic) FCTheme *theme;
@property (nonatomic,strong) FAQOptions *faqOptions;
@property BOOL isFilteredView;
@property (nonatomic, strong) FCCategoryViewBehaviour *categoryViewBehaviour;

@end

@implementation FCArticlesController

-(instancetype)initWithCategory:(FCCategories *)category{
    self = [self init];
    if (self) {
        self.category = category;
    }
    return self;
}

-(instancetype) init {
    self = [super init];
    if (self) {
        self.faqOptions = [FAQOptions new];
        self.theme = [FCTheme sharedInstance];
    }
    return self;
}

-(void)willMoveToParentViewController:(UIViewController *)parent{
    [super willMoveToParentViewController:parent];
    self.tableView.separatorColor = [[FCTheme sharedInstance] articleListCellSeperatorColor];
    self.tableView.backgroundColor = [[FCTheme sharedInstance] articleListBackgroundColor];
    FCContainerController *containerCtr =  (FCContainerController*)self.parentViewController;
    [containerCtr.footerView setViewColor:self.tableView.backgroundColor];
    [self setNavigationItem];
    if([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]){
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    if([FCFAQUtil hasFilteredViewTitle:self.faqOptions]){
        if(self.faqOptions.filteredType == ARTICLE){
            parent.navigationItem.title = [self.faqOptions filteredViewTitle];
        }
        else{
            parent.navigationItem.title = self.category.title;
        }
    }
    else{
        if(self.category){
            parent.navigationItem.title = self.category.title;
        }
        else{
            parent.navigationItem.title = HLLocalizedString(LOC_FAQ_TITLE_TEXT);
        }
    }
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if(self.isFilteredView && !self.category){
        [FCControllerUtils configureGestureDelegate:nil forController:self withEmbedded:true];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self updateDataSource];
}

-(BOOL)canDisplayFooterView{
    return self.faqOptions && self.faqOptions.showContactUsOnFaqScreens && !self.faqOptions.showContactUsOnAppBar;
}

-(void)updateDataSource{
    self.articles = @[];
    [self.tableView reloadData];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"position" ascending: YES];
    
    if(self.category){
        [[FCDataManager sharedInstance]fetchAllArticlesOfCategoryID:self.category.categoryID handler:^(NSArray *articles, NSError *error) {
          
            NSArray *sortedArticles = [[self.category.articles allObjects] sortedArrayUsingDescriptors:@[sortDescriptor]];
            self.articles = sortedArticles;
            [self.tableView reloadData];
        }];
    }
    else if (self.isFilteredView){
        NSManagedObjectContext *ctx = [FCDataManager sharedInstance].mainObjectContext;
        [[FCTagManager sharedInstance] getArticlesForTags:self.faqOptions.tags inContext:ctx withCompletion:^(NSArray<FCArticles *> *articles) {
             [ctx performBlock:^{
                 NSMutableArray *matchingArticles = [articles mutableCopy];
                 NSSortDescriptor *categorySorter = [[NSSortDescriptor alloc] initWithKey:@"category.position" ascending:YES];
                 NSSortDescriptor *articleSorter = [[NSSortDescriptor alloc] initWithKey:@"position" ascending:YES];
                 [matchingArticles sortUsingDescriptors:@[categorySorter, articleSorter]];
                 self.articles = matchingArticles;
                 [self.tableView reloadData];
             }];
         }];
    }
}

-(void)closeButton:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)setNavigationItem{
    
    UIBarButtonItem *searchBarButton = [[FCBarButtonItem alloc] initWithImage:[self.theme getImageWithKey:IMAGE_SEARCH_ICON]
                                                                        style:UIBarButtonItemStylePlain target:self action:@selector(searchButtonAction:)];
    [self configureBackButton];
    NSMutableArray *rtNavBarItems = [NSMutableArray new];
    if(!self.isFilteredView){
         [rtNavBarItems addObject:searchBarButton];
    }
    if(self.faqOptions && self.faqOptions.showContactUsOnAppBar && self.faqOptions.showContactUsOnFaqScreens){
        UIBarButtonItem *contactUsBarButton = [[FCBarButtonItem alloc] initWithImage:[self.theme getImageWithKey:IMAGE_CONTACT_US_ICON]
                                                                               style:UIBarButtonItemStylePlain target:self action:@selector(contactUsButtonAction:)];
        [rtNavBarItems addObject:contactUsBarButton];
    }
    
    if(!self.category && !self.embedded){
        UIBarButtonItem *closeButton = [[FCBarButtonItem alloc]initWithTitle:HLLocalizedString(LOC_FAQ_CLOSE_BUTTON_TEXT) style:UIBarButtonItemStylePlain target:self action:@selector(closeButton:)];
        self.parentViewController.navigationItem.leftBarButtonItem = closeButton;
    }
    self.parentViewController.navigationItem.rightBarButtonItems = rtNavBarItems;
}

-(void)contactUsButtonAction:(id)sender{
    [self.categoryViewBehaviour launchConversations];
}

-(UIViewController<UIGestureRecognizerDelegate> *)gestureDelegate{
    return self;
}

-(void)searchButtonAction:(id)sender{
    FCSearchViewController *searchViewController = [[FCSearchViewController alloc] init];
    [FCFAQUtil setFAQOptions:self.faqOptions onController:searchViewController];
    UINavigationController *navController = [[UINavigationController alloc]initWithRootViewController:searchViewController];
    [navController setModalPresentationStyle:UIModalPresentationCustom];
    [self presentViewController:navController animated:NO completion:nil];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = @"HLArticleCell";
    
    FCArticleListCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (!cell) {
        cell = [[FCArticleListCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    if (indexPath.row < self.articles.count) {
        FCArticles *article = self.articles[indexPath.row];
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
    
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:[self.theme faqListCellSelectedColor]];
    [cell setSelectedBackgroundView:view];
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)sectionIndex{
    return self.articles.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UIFont *cellFont = [self.theme articleListFont];
    CGFloat heightOfcell = [FCListViewController heightOfCell:cellFont];
    return heightOfcell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row < self.articles.count) {
        FCArticles *article = self.articles[indexPath.row];
        [FCFAQUtil launchArticle:article withNavigationCtlr:self andFaqOptions:self.faqOptions fromLink:false];
    }
}

-(void) setFAQOptions:(FAQOptions *)options {
    self.faqOptions = options;
    self.isFilteredView = [FCFAQUtil hasTags:self.faqOptions];
}

@end
