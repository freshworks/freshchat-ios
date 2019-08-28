//
//  HLCategoriesListController.m
//  
//
//  Created by Aravinth Chandran on 23/09/15.
//
//

#import "FCCategoryListController.h"
#import "FCFAQServices.h"
#import "FCLocalNotification.h"
#import "FCDataManager.h"
#import "FCCategories.h"
#import "FCMacros.h"
#import "FCArticlesController.h"
#import "FCContainerController.h"
#import "FCTheme.h"
#import "FCSearchViewController.h"
#import "FreshchatSDK.h"
#import "FCLocalization.h"
#import "FCBarButtonItem.h"
#import "FCCell.h"
#import "FCEmptyResultView.h"
#import "FCAutolayoutHelper.h"
#import "FCReachabilityManager.h"
#import "FCFAQUtil.h"
#import "FCTagManager.h"
#import "FCCategoryViewBehaviour.h"
#import "FCLoadingViewBehaviour.h"
#import "FCControllerUtils.h"
#import "FCUtilities.h"

@interface FCCategoryListController () <HLCategoryViewBehaviourDelegate,HLLoadingViewBehaviourDelegate>

@property (nonatomic, strong)NSArray *categories;
@property (nonatomic, strong)FCTheme *theme;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) FCEmptyResultView *emptyResultView;
@property (nonatomic, strong) FAQOptions *faqOptions;
@property (nonatomic, strong) FCCategoryViewBehaviour *categoryViewBehaviour;
@property (nonatomic, strong) FCLoadingViewBehaviour *loadingViewBehaviour;

@end

@implementation FCCategoryListController

-(void) setFAQOptions:(FAQOptions *)options{
    self.faqOptions = options;
}

-(FCCategoryViewBehaviour*)categoryViewBehaviour {
    if(_categoryViewBehaviour == nil){
        _categoryViewBehaviour = [[FCCategoryViewBehaviour alloc] initWithViewController:self andFaqOptions:self.faqOptions];
    }
    return _categoryViewBehaviour;
}

-(FCLoadingViewBehaviour*)loadingViewBehaviour {
    if(_loadingViewBehaviour == nil){
        _loadingViewBehaviour = [[FCLoadingViewBehaviour alloc] initWithViewController:self withType:1];
    }
    return _loadingViewBehaviour;
}


-(BOOL)isEmbedded {
    return self.embedded;
}

-(UIView *)contentDisplayView{
    return self.tableView;
}

-(NSString *)emptyText{
    return HLLocalizedString(LOC_EMPTY_FAQ_TEXT);
}

-(NSString *)loadingText{
    return HLLocalizedString(LOC_LOADING_FAQ_TEXT);
}

-(void)willMoveToParentViewController:(UIViewController *)parent{
    self.theme = [FCTheme sharedInstance];
    [super willMoveToParentViewController:parent];
    self.tableView.separatorColor = [[FCTheme sharedInstance] faqListCellSeparatorColor];
    self.tableView.backgroundColor = [[FCTheme sharedInstance] faqCategoryBackgroundColor];
    if([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)])
    {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    FCContainerController * containerCtr =  (FCContainerController*)self.parentViewController;
    [containerCtr.footerView setViewColor:self.tableView.backgroundColor];
    parent.navigationItem.title = HLLocalizedString(LOC_FAQ_TITLE_TEXT);
    [FCCategoryViewBehaviour updateEventForOpenCategoryWithTags:self.faqOptions.tags];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.loadingViewBehaviour load:self.categories.count];
    [self.categoryViewBehaviour load];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [FCControllerUtils configureGestureDelegate:nil forController:self withEmbedded:[self isEmbedded]];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.categoryViewBehaviour unload];
}


- (void) onCategoriesUpdated:(NSArray<FCCategories *> *) categories {
    BOOL refreshData = NO;
    if ( self.categories ) {
        refreshData = YES;
    }
    self.categories = categories;
    [self.categoryViewBehaviour setNavigationItem];
    refreshData = refreshData || (self.categories.count > 0);
    if ( ![[FCReachabilityManager sharedInstance] isReachable] || refreshData ) {
        [self.loadingViewBehaviour updateResultsView:NO andCount:categories.count];
    }
    [self.tableView reloadData];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:[self.theme faqListCellSelectedColor]];
    [cell setSelectedBackgroundView:view];
    
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

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = @"HLCategoriesCell";
    FCCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[FCCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier isChannelCell:NO];
    }
    if (indexPath.row < self.categories.count) {
        FCCategories *category =  self.categories[indexPath.row];
        cell.titleLabel.text  = trimString(category.title);
        cell.detailLabel.text = trimString(category.categoryDescription);
        cell.separatorInset = UIEdgeInsetsZero;
        [FCUtilities loadImageAndPlaceholderBgWithUrl:category.iconURL forView:cell.imgView withColor:[[FCTheme sharedInstance] faqPlaceholderIconBackgroundColor] andName:category.title];
    }
    
    [cell adjustPadding];
    
    return cell;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)sectionIndex{
    return self.categories.count;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    FCCategories *category =  self.categories[indexPath.row];
    FCArticlesController *articleController = [[FCArticlesController alloc]initWithCategory:category];
    [FCFAQUtil setFAQOptions: self.faqOptions onController:articleController];
    FCContainerController *container = [[FCContainerController alloc]initWithController:articleController andEmbed:NO];
    
    [self.navigationController pushViewController:container animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 64;
}

-(BOOL)canDisplayFooterView{
    return [self.categoryViewBehaviour canDisplayFooterView];
}

@end
