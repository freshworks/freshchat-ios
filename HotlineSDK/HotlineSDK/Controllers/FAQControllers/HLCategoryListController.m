//
//  HLCategoriesListController.m
//  
//
//  Created by Aravinth Chandran on 23/09/15.
//
//

#import "HLCategoryListController.h"
#import "HLFAQServices.h"
#import "FDLocalNotification.h"
#import "KonotorDataManager.h"
#import "HLCategory.h"
#import "HLMacros.h"
#import "HLArticlesController.h"
#import "HLContainerController.h"
#import "FCTheme.h"
#import "HLSearchViewController.h"
#import "Freshchat.h"
#import "HLLocalization.h"
#import "FDUtilities.h"
#import "FDBarButtonItem.h"
#import "FDCell.h"
#import "HLEmptyResultView.h"
#import "FDAutolayoutHelper.h"
#import "FDReachabilityManager.h"
#import "HLFAQUtil.h"
#import "HLTagManager.h"
#import "HLCategoryViewBehaviour.h"
#import "HLLoadingViewBehaviour.h"
#import "HLControllerUtils.h"

@interface HLCategoryListController () <HLCategoryViewBehaviourDelegate,HLLoadingViewBehaviourDelegate>

@property (nonatomic, strong)NSArray *categories;
@property (nonatomic, strong)FCTheme *theme;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) HLEmptyResultView *emptyResultView;
@property (nonatomic, strong) FAQOptions *faqOptions;
@property (nonatomic, strong) HLCategoryViewBehaviour *categoryViewBehaviour;
@property (nonatomic, strong) HLLoadingViewBehaviour *loadingViewBehaviour;

@end

@implementation HLCategoryListController

-(void) setFAQOptions:(FAQOptions *)options{
    self.faqOptions = options;
}

-(HLCategoryViewBehaviour*)categoryViewBehaviour {
    if(_categoryViewBehaviour == nil){
        _categoryViewBehaviour = [[HLCategoryViewBehaviour alloc] initWithViewController:self andFaqOptions:self.faqOptions];
    }
    return _categoryViewBehaviour;
}

-(HLLoadingViewBehaviour*)loadingViewBehaviour {
    if(_loadingViewBehaviour == nil){
        _loadingViewBehaviour = [[HLLoadingViewBehaviour alloc] initWithViewController:self];
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
    parent.navigationItem.title = HLLocalizedString(LOC_FAQ_TITLE_TEXT);
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.loadingViewBehaviour load:self.categories.count];
    [self.categoryViewBehaviour load];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [HLControllerUtils configureGestureDelegate:nil forController:self withEmbedded:[self isEmbedded]];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.categoryViewBehaviour unload];
}


- (void) onCategoriesUpdated:(NSArray<HLCategory *> *) categories {
    BOOL refreshData = NO;
    if ( self.categories ) {
        refreshData = YES;
    }
    self.categories = categories;
    [self.categoryViewBehaviour setNavigationItem];
    refreshData = refreshData || (self.categories.count > 0);
    if ( ![[FDReachabilityManager sharedInstance] isReachable] || refreshData ) {
        [self.loadingViewBehaviour updateResultsView:NO andCount:categories.count];
    }
    [self.tableView reloadData];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = @"HLCategoriesCell";
    FDCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[FDCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier isChannelCell:NO];
    }
    if (indexPath.row < self.categories.count) {
        HLCategory *category =  self.categories[indexPath.row];
        cell.titleLabel.text  = category.title;
        cell.detailLabel.text = category.categoryDescription;
        cell.layer.borderWidth = 0.5f;
        cell.layer.borderColor = [self.theme tableViewCellSeparatorColor].CGColor;
        if(!category.icon){
            cell.imgView.image = [FDCell generateImageForLabel:category.title];
        }
        else{
            cell.imgView.image = [UIImage imageWithData:category.icon];
        }
    }
    
    [cell adjustPadding];
    
    return cell;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)sectionIndex{
    return self.categories.count;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    HLCategory *category =  self.categories[indexPath.row];
    HLArticlesController *articleController = [[HLArticlesController alloc]initWithCategory:category];
    [HLFAQUtil setFAQOptions: self.faqOptions onController:articleController];
    HLContainerController *container = [[HLContainerController alloc]initWithController:articleController andEmbed:NO];
    
    [self.navigationController pushViewController:container animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 64;
}

-(BOOL)canDisplayFooterView{
    return [self.categoryViewBehaviour canDisplayFooterView];
}

@end
