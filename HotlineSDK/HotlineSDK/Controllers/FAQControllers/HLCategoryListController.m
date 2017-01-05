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
#import "FDSolutionUpdater.h"
#import "HLTheme.h"
#import "HLSearchViewController.h"
#import "Hotline.h"
#import "HLLocalization.h"
#import "FDUtilities.h"
#import "FDBarButtonItem.h"
#import "FDCell.h"
#import "HLEmptyResultView.h"
#import "FDAutolayoutHelper.h"
#import "FDReachabilityManager.h"
#import "HLArticleUtil.h"

@interface HLCategoryListController ()

@property (nonatomic, strong)NSArray *categories;
@property (nonatomic, strong)HLTheme *theme;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) HLEmptyResultView *emptyResultView;
@property (nonatomic, strong) FAQOptions *faqOptions;

@end

@implementation HLCategoryListController

-(void) setFAQOptions:(FAQOptions *)options{
    self.faqOptions = options;
}

-(void)willMoveToParentViewController:(UIViewController *)parent{
    self.theme = [HLTheme sharedInstance];
    [super willMoveToParentViewController:parent];
    parent.navigationItem.title = HLLocalizedString(LOC_FAQ_TITLE_TEXT);
    [self setNavigationItem];
    [self updateResultsView:YES];
    [self addLoadingIndicator];
}

-(void)addLoadingIndicator{
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false;
    [self.view insertSubview:self.activityIndicator aboveSubview:self.tableView];
    [self.activityIndicator startAnimating];
    [FDAutolayoutHelper centerX:self.activityIndicator onView:self.view M:1 C:0];
    [FDAutolayoutHelper centerY:self.activityIndicator onView:self.view M:1.5 C:0];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];    
    [self localNotificationSubscription];
    [self fetchUpdates];
    [self updateCategories];
}

-(HLEmptyResultView *)emptyResultView
{
    if (!_emptyResultView) {
        _emptyResultView = [[HLEmptyResultView alloc]initWithImage:[self.theme getImageWithKey:IMAGE_FAQ_ICON] andText:@""];
        _emptyResultView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _emptyResultView;
}

//TODO: Remove duplicate code
-(void)updateCategories{
    [[KonotorDataManager sharedInstance]fetchAllSolutions:^(NSArray *solutions, NSError *error) {
        if (!error) {
            BOOL refreshData = NO;
            if ( self.categories ) {
                refreshData = YES;
            }
            self.categories = solutions;
            [self setNavigationItem];
            refreshData = refreshData || (self.categories.count > 0);
            if ( ![[FDReachabilityManager sharedInstance] isReachable] || refreshData ) {
                [self updateResultsView:NO];
            }
            [self.tableView reloadData];
        }
    }];
}

-(void)updateResultsView:(BOOL)isLoading
{
    if(self.categories.count == 0) {
        NSString *message;
        if(isLoading){
            message = HLLocalizedString(LOC_LOADING_FAQ_TEXT);
        }
        else if(![[FDReachabilityManager sharedInstance] isReachable]){
            message = HLLocalizedString(LOC_OFFLINE_INTERNET_MESSAGE);
            [self removeLoadingIndicator];
        }
        else {
            message = HLLocalizedString(LOC_EMPTY_FAQ_TEXT);
            [self removeLoadingIndicator];
        }
        self.emptyResultView.emptyResultLabel.text = message;
        [self.view addSubview:self.emptyResultView];
        [FDAutolayoutHelper center:self.emptyResultView onView:self.view];
    }
    else{
        self.emptyResultView.frame = CGRectZero;
        [self.emptyResultView removeFromSuperview];
        [self removeLoadingIndicator];
    }
}

-(void)removeLoadingIndicator{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicator removeFromSuperview];
    });
}

-(void)setNavigationItem{
    
    UIBarButtonItem *contactUsBarButton = [[FDBarButtonItem alloc] initWithImage:[self.theme getImageWithKey:IMAGE_CONTACT_US_ICON]
                                                                           style:UIBarButtonItemStylePlain target:self action:@selector(contactUsButtonAction:)];
    UIBarButtonItem *searchBarButton = [[FDBarButtonItem alloc] initWithImage:[self.theme getImageWithKey:IMAGE_SEARCH_ICON]
                                                                           style:UIBarButtonItemStylePlain target:self action:@selector(searchButtonAction:)];
    
    UIBarButtonItem *closeButton = [[FDBarButtonItem alloc]initWithTitle:HLLocalizedString(LOC_FAQ_CLOSE_BUTTON_TEXT) style:UIBarButtonItemStylePlain target:self action:@selector(closeButton:)];
    
    if (!self.embedded) {
        self.parentViewController.navigationItem.leftBarButtonItem = closeButton;
        [self.navigationController.interactivePopGestureRecognizer setEnabled:NO];
    }
    else {
        [self configureBackButtonWithGestureDelegate:nil];
    }
    NSMutableArray *rightBarItems = [NSMutableArray new];
    if(self.categories.count){
        [rightBarItems addObject:searchBarButton];
    }
    if(self.faqOptions && self.faqOptions.showContactUsOnAppBar){
        [rightBarItems addObject:contactUsBarButton];
    }
    self.parentViewController.navigationItem.rightBarButtonItems = rightBarItems;
}

-(void)closeButton:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)searchButtonAction:(id)sender{
    HLSearchViewController *searchViewController = [[HLSearchViewController alloc] init];
    [HLArticleUtil setFAQOptions:self.faqOptions andViewController:searchViewController];
    UINavigationController *navController = [[UINavigationController alloc]initWithRootViewController:searchViewController];
    [navController setModalPresentationStyle:UIModalPresentationCustom];
    [self presentViewController:navController animated:NO completion:nil];
}

-(void)contactUsButtonAction:(id)sender{
    [[Hotline sharedInstance]showConversations:self];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self localNotificationUnSubscription];
}

-(void)localNotificationUnSubscription{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HOTLINE_SOLUTIONS_UPDATED object:nil];
}

-(void)localNotificationSubscription{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSolutions)
                                                 name:HOTLINE_SOLUTIONS_UPDATED object:nil];
}

-(void)updateSolutions{
    dispatch_async(dispatch_get_main_queue(), ^{
        HideNetworkActivityIndicator();
        [self updateCategories];
    });
}

-(void)fetchUpdates{
    FDSolutionUpdater *updater = [[FDSolutionUpdater alloc]init];
    [[KonotorDataManager sharedInstance]areSolutionsEmpty:^(BOOL isEmpty) {
        if(isEmpty){
            [updater resetTime];
        }
        ShowNetworkActivityIndicator();
        [updater fetchWithCompletion:^(BOOL isFetchPerformed, NSError *error) {
            HideNetworkActivityIndicator();
        }];
    }];
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
    [HLArticleUtil setFAQOptions:self.faqOptions andViewController:articleController];
    HLContainerController *container = [[HLContainerController alloc]initWithController:articleController andEmbed:NO];
    [self.navigationController pushViewController:container animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 64;
}

-(BOOL)canDisplayFooterView{
    return self.faqOptions && self.faqOptions.showContactUsOnFaqScreens;
}

@end
