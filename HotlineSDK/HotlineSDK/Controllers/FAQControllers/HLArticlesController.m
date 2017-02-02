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
#import "HLFAQUtil.h"
#import "HLTagManager.h"
#import "HLLocalization.h"
#import "HLEventManager.h"
#import "HLControllerUtils.h"

@interface HLArticlesController ()

@property (nonatomic, strong)HLCategory *category;
@property (nonatomic, strong)NSArray *articles;
@property (strong, nonatomic) HLTheme *theme;
@property (nonatomic,strong) FAQOptions *faqOptions;
@property BOOL isFilteredView;

@end

@implementation HLArticlesController

-(instancetype)initWithCategory:(HLCategory *)category{
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
        self.theme = [HLTheme sharedInstance];
    }
    return self;
}

-(void)willMoveToParentViewController:(UIViewController *)parent{
    [super willMoveToParentViewController:parent];
    self.tableView.separatorColor = [[HLTheme sharedInstance] tableViewCellSeparatorColor];
    [self setNavigationItem];
    if([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]){
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    if([HLFAQUtil hasFilteredViewTitle:self.faqOptions]){
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
    if(self.isFilteredView){
        [HLControllerUtils configureGestureDelegate:nil forController:self withEmbedded:true];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self updateDataSource];
}

-(BOOL)canDisplayFooterView{
    return self.faqOptions && self.faqOptions.showContactUsOnFaqScreens;
}

-(void)updateDataSource{
    self.articles = @[];
    [self.tableView reloadData];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"position" ascending: YES];
    
    if(self.category){
        [[KonotorDataManager sharedInstance]fetchAllArticlesOfCategoryID:self.category.categoryID handler:^(NSArray *articles, NSError *error) {
          
            NSArray *sortedArticles = [[self.category.articles allObjects] sortedArrayUsingDescriptors:@[sortDescriptor]];
            self.articles = sortedArticles;
            [self.tableView reloadData];
        }];
    }
    else if (self.isFilteredView){
        NSManagedObjectContext *ctx = [KonotorDataManager sharedInstance].mainObjectContext;
        [[HLTagManager sharedInstance] getArticlesForTags:self.faqOptions.tags inContext:ctx withCompletion:^(NSArray<HLArticle *> *articles) {
             [ctx performBlock:^{
                 NSMutableArray *matchingArticles = [articles mutableCopy];
                 NSSortDescriptor *categorySorter = [[NSSortDescriptor alloc] initWithKey:@"category.position" ascending:YES];
                 NSSortDescriptor *articleSorter = [[NSSortDescriptor alloc] initWithKey:@"position" ascending:YES];
                 [matchingArticles sortUsingDescriptors:@[categorySorter, articleSorter]];
                 
                 self.articles = matchingArticles;
                 if(!self.embedded){
                     UIBarButtonItem *closeButton = [[FDBarButtonItem alloc]initWithTitle:HLLocalizedString(LOC_FAQ_CLOSE_BUTTON_TEXT) style:UIBarButtonItemStylePlain target:self action:@selector(closeButton:)];
                     self.parentViewController.navigationItem.leftBarButtonItem = closeButton;
                 }
                 [self.tableView reloadData];
             }];
         }];
    }
}

-(void)closeButton:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)setNavigationItem{
    UIBarButtonItem *searchBarButton = [[FDBarButtonItem alloc] initWithImage:[self.theme getImageWithKey:IMAGE_SEARCH_ICON]
                                                                        style:UIBarButtonItemStylePlain target:self action:@selector(searchButtonAction:)];
    [self configureBackButton];
    if(!self.isFilteredView){
        self.parentViewController.navigationItem.rightBarButtonItems = @[searchBarButton];
    }
}

-(UIViewController<UIGestureRecognizerDelegate> *)gestureDelegate{
    return self;
}

-(void)searchButtonAction:(id)sender{
    [[HLEventManager sharedInstance] submitSDKEvent:HLEVENT_FAQ_SEARCH_LAUNCH withBlock:^(HLEvent *event) {
        [event propKey:HLEVENT_PARAM_SOURCE andVal:HLEVENT_LAUNCH_SOURCE_ARTICLE_LIST];
    }];
    HLSearchViewController *searchViewController = [[HLSearchViewController alloc] init];
    [HLFAQUtil setFAQOptions:self.faqOptions onController:searchViewController];
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
        [HLFAQUtil launchArticle:article withNavigationCtlr:self.navigationController faqOptions:self.faqOptions andSource:HLEVENT_LAUNCH_SOURCE_ARTICLE_LIST];
    }
}

-(void) setFAQOptions:(FAQOptions *)options {
    self.faqOptions = options;
    self.isFilteredView = [HLFAQUtil hasTags:self.faqOptions];
}

@end
