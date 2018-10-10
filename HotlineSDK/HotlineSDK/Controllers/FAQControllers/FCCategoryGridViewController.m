    //
//  HLCollectionView.m
//  HotlineSDK
//
//  Created by kirthikas on 22/09/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FCCategoryGridViewController.h"
#import "FCGridViewCell.h"
#import "FCContainerController.h"
#import "FCArticlesController.h"
#import "FCDataManager.h"
#import "FCMacros.h"
#import "FCRanking.h"
#import "FCLocalNotification.h"
#import "FCCategories.h"
#import "FCTheme.h"
#import "FCSearchViewController.h"
#import "FCSearchBar.h"
#import "FreshchatSDK.h"
#import "FCLocalization.h"
#import "FCBarButtonItem.h"
#import "FCEmptyResultView.h"
#import "FCCell.h"
#import "FCAutolayoutHelper.h"
#import "FCReachabilityManager.h"
#import "FCFAQUtil.h"
#import "FCTagManager.h"
#import "FCCategoryViewBehaviour.h"
#import "FCLoadingViewBehaviour.h"
#import "FCControllerUtils.h"
#import "FCUtilities.h"

@interface FCCategoryGridViewController () <UIScrollViewDelegate,UISearchBarDelegate,FDMarginalViewDelegate,HLCategoryViewBehaviourDelegate,HLLoadingViewBehaviourDelegate>

@property (nonatomic, strong) NSArray *categories;
@property (nonatomic, strong) FCSearchBar *searchBar;
@property (nonatomic, strong) FCMarginalView *footerView;
@property (nonatomic, strong) UILabel  *noSolutionsLabel;
@property (nonatomic, strong) FCTheme *theme;
@property (nonatomic, strong) FAQOptions *faqOptions;
@property (nonatomic, strong) FCCategoryViewBehaviour *categoryViewBehaviour;
@property (nonatomic, strong) FCLoadingViewBehaviour *loadingViewBehaviour;

@end

@implementation FCCategoryGridViewController

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
        _loadingViewBehaviour = [[FCLoadingViewBehaviour alloc] initWithViewController:self withType:1 isWaitingForJWT:FALSE];
    }
    return _loadingViewBehaviour;
}

-(BOOL)isEmbedded {
    return self.embedded;
}

-(UIView *)contentDisplayView{
    return self.collectionView;
}

-(NSString *)emptyText{
    return HLLocalizedString(LOC_EMPTY_FAQ_TEXT);
}

-(NSString *)loadingText{
    return HLLocalizedString(LOC_LOADING_FAQ_TEXT);
}


-(void)willMoveToParentViewController:(UIViewController *)parent{
    parent.navigationItem.title = HLLocalizedString(LOC_FAQ_TITLE_TEXT);
    self.theme = [FCTheme sharedInstance];
    [self setupSubviews];
    [self adjustUIBounds];
    [self theming];
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

-(void)setupSubviews{
    [self setupCollectionView];
    [self setupSearchBar];
}

-(void)viewWillLayoutSubviews{
    self.searchBar.frame= CGRectMake(0, 0, self.view.frame.size.width, 65);
}

-(void)theming{
    [self.searchDisplayController.searchResultsTableView setBackgroundColor:[self.theme faqCategoryBackgroundColor]];
}

-(void)setupSearchBar{
    self.searchBar = [[FCSearchBar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = HLLocalizedString(@"Search Placeholder");
    self.searchBar.showsCancelButton=YES;
    
    [self.view addSubview:self.searchBar];

    UIView *mainSubView = [self.searchBar.subviews lastObject];
    
    for (id subview in mainSubView.subviews) {
        if ([subview isKindOfClass:[UITextField class]]) {
            UITextField *textField = (UITextField *)subview;
            textField.backgroundColor = [self.theme searchBarInnerBackgroundColor];
        }
    }
    
    self.searchBar.hidden = YES;
}

-(void)adjustUIBounds{
    self.edgesForExtendedLayout=UIRectEdgeNone;
    self.navigationController.view.backgroundColor = [self.theme searchBarOuterBackgroundColor];
}

- (void) onCategoriesUpdated:(NSArray<FCCategories *> *)categories {
    BOOL refreshData = NO;
    if(self.categories) {
        refreshData = YES;
    }
    self.categories = categories;
    [self.categoryViewBehaviour setNavigationItem];
    refreshData = refreshData || (self.categories.count > 0);
    if ( ![[FCReachabilityManager sharedInstance] isReachable] || refreshData ) {
        [self.loadingViewBehaviour  updateResultsView:NO andCount:self.categories.count];
    }
    [self.collectionView reloadData];
}

-(void)setupCollectionView{
    
    UICollectionViewFlowLayout* flowLayout = [[UICollectionViewFlowLayout alloc]init];
    self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.contentInset = UIEdgeInsetsMake(5, 5, 5, 5);
    
    self.view.backgroundColor = [[FCTheme sharedInstance] faqCategoryBackgroundColor];
    self.collectionView.backgroundColor = [[FCTheme sharedInstance] faqCategoryBackgroundColor];
    FCContainerController * containerCtr =  (FCContainerController*)self.parentViewController;
    [containerCtr.footerView setViewColor:self.collectionView.backgroundColor];
    
    self.footerView = [[FCMarginalView alloc] initWithDelegate:self];
    
    [self.view addSubview:self.footerView];
    [self.view addSubview:self.collectionView];
    
    NSDictionary *views = @{ @"collectionView" : self.collectionView, @"footerView" : self.footerView};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[collectionView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[footerView]|" options:0 metrics:nil views:views]];
    if([self canDisplayFooterView]){
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[collectionView][footerView(44)]|" options:0 metrics:nil views:views]];
    }
    else {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[collectionView][footerView(0)]|" options:0 metrics:nil views:views]];
    }
    
    //Collection view subclass
    [self.collectionView registerClass:[FCGridViewCell class] forCellWithReuseIdentifier:@"FAQ_GRID_CELL"];
}

-(void)marginalView:(FCMarginalView *)marginalView handleTap:(id)sender{
    [self.categoryViewBehaviour launchConversations];
}

#pragma mark - Collection view delegate

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section{
    return CGSizeMake(self.collectionView.bounds.size.width, 44);
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return (self.categories) ? self.categories.count : 0;
}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0); // top, left, bottom, right
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FCGridViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"FAQ_GRID_CELL" forIndexPath:indexPath];
    if (!cell) {
        CGFloat cellSize = [UIScreen mainScreen].bounds.size.width/2;
        cell = [[FCGridViewCell alloc] initWithFrame:CGRectMake(0, 0, cellSize, cellSize)];
    }
    if (indexPath.row < self.categories.count){
        FCCategories *category = self.categories[indexPath.row];
        cell.label.text = category.title;
        cell.backgroundColor = [self.theme faqCategoryBackgroundColor];
        cell.cardView.backgroundColor = [[FCTheme sharedInstance] gridViewCardBackgroundColor];
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [FCUtilities loadImageAndPlaceholderBgWithUrl:category.iconURL forView:cell.imageView withColor:[[FCTheme sharedInstance] faqPlaceholderIconBackgroundColor] andName:category.title];
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (IS_IPAD) {
        return CGSizeMake( (([UIScreen mainScreen].bounds.size.width-10)/3), (([UIScreen mainScreen].bounds.size.width-10)/3));
    }
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        return CGSizeMake( (([UIScreen mainScreen].bounds.size.width-10)/3), (([UIScreen mainScreen].bounds.size.width-10)/3));
    }
    return CGSizeMake( (([UIScreen mainScreen].bounds.size.width-10)/2), (([UIScreen mainScreen].bounds.size.width-10)/2));
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row < self.categories.count) {
        FCCategories *category = self.categories[indexPath.row];
        FCArticlesController *articleController = [[FCArticlesController alloc] initWithCategory:category];
        [FCFAQUtil setFAQOptions:self.faqOptions onController:articleController];
        FCContainerController *container = [[FCContainerController alloc]initWithController:articleController andEmbed:NO];
        [self.navigationController pushViewController:container animated:YES];
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0f;
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    [self.categoryViewBehaviour setNavigationItem];
    [self.collectionView reloadData];
}

-(BOOL)canDisplayFooterView{
    return [self.categoryViewBehaviour canDisplayFooterView];
}

@end
