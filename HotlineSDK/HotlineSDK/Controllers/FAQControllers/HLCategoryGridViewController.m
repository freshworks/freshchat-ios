//
//  HLCollectionView.m
//  HotlineSDK
//
//  Created by kirthikas on 22/09/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "HLCategoryGridViewController.h"
#import "HLGridViewCell.h"
#import "HLContainerController.h"
#import "HLArticlesController.h"
#import "KonotorDataManager.h"
#import "HLMacros.h"
#import "FDRanking.h"
#import "HLArticlesController.h"
#import "FDLocalNotification.h"
#import "HLCategory.h"
#import "FDSolutionUpdater.h"
#import "HLTheme.h"
#import "HLSearchViewController.h"
#import "FDSearchBar.h"
#import "FDUtilities.h"
#import "Hotline.h"
#import "HLLocalization.h"
#import "FDBarButtonItem.h"
#import "HLEmptyResultView.h"
#import "FDCell.h"
#import "FDAutolayoutHelper.h"
#import "FDReachabilityManager.h"
#import "HLArticleUtil.h"

@interface HLCategoryGridViewController () <UIScrollViewDelegate,UISearchBarDelegate,FDMarginalViewDelegate>

@property (nonatomic, strong) NSArray *categories;
@property (nonatomic, strong) FDSearchBar *searchBar;
@property (nonatomic, strong) FDMarginalView *footerView;
@property (nonatomic, strong) UILabel  *noSolutionsLabel;
@property (nonatomic, strong) HLTheme *theme;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) HLEmptyResultView *emptyResultView;
@property (nonatomic, strong) FAQOptions *faqOptions;

@end

@implementation HLCategoryGridViewController

-(void) setFAQOptions:(FAQOptions *)options{
    self.faqOptions = options;
}

-(BOOL)canDisplayFooterView{
    return self.faqOptions && self.faqOptions.showContactUsOnFaqScreens;
}

-(void)willMoveToParentViewController:(UIViewController *)parent{
    if (self.faqOptions.tags && self.tagsArray.count >0 && self.faqOptions.filteredViewTitle.length >0){
        parent.navigationItem.title = self.faqOptions.filteredViewTitle;
    }
    else{
        parent.navigationItem.title = HLLocalizedString(LOC_FAQ_TITLE_TEXT);
    }
    [self setNavigationItem];
    self.theme = [HLTheme sharedInstance];
    self.view.backgroundColor = [UIColor whiteColor];
    [self updateCategories];
    [self setupSubviews];
    [self adjustUIBounds];
    [self theming];
    [self addLoadingIndicator];
}

-(void)addLoadingIndicator{
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false;
    [self.view insertSubview:self.activityIndicator aboveSubview:self.collectionView];
    [self.activityIndicator startAnimating];
    [FDAutolayoutHelper centerX:self.activityIndicator onView:self.view M:1 C:0];
    [FDAutolayoutHelper centerY:self.activityIndicator onView:self.view M:1.5 C:0];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self localNotificationSubscription];
    [self fetchUpdates];
}

-(void)setupSubviews{
    [self setupCollectionView];
    [self setupSearchBar];
}

-(void)viewWillLayoutSubviews{
    self.searchBar.frame= CGRectMake(0, 0, self.view.frame.size.width, 65);
}

-(void)theming{
    [self.searchDisplayController.searchResultsTableView setBackgroundColor:[self.theme backgroundColorSDK]];
}

-(void)setupSearchBar{
    self.searchBar = [[FDSearchBar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
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

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    self.searchBar.hidden = YES;
    self.parentViewController.navigationController.navigationBarHidden=NO;
}

-(void)adjustUIBounds{
    self.edgesForExtendedLayout=UIRectEdgeNone;
    self.navigationController.view.backgroundColor = [self.theme searchBarOuterBackgroundColor];
}

-(void)setNavigationItem{

    UIBarButtonItem *contactUsBarButton = [[FDBarButtonItem alloc] initWithImage:[self.theme getImageWithKey:IMAGE_CONTACT_US_ICON]
                                                                           style:UIBarButtonItemStylePlain target:self action:@selector(contactUsButtonAction:)];
    UIBarButtonItem *searchBarButton = [[FDBarButtonItem alloc] initWithImage:[self.theme getImageWithKey:IMAGE_SEARCH_ICON]
                                                                        style:UIBarButtonItemStylePlain target:self action:@selector(searchButtonAction:)];
    
    UIBarButtonItem *closeButton = [[FDBarButtonItem alloc]initWithTitle:HLLocalizedString(LOC_FAQ_CLOSE_BUTTON_TEXT) style:UIBarButtonItemStylePlain target:self action:@selector(closeButton:)];
    
    //TODO: Need to revisit this to get rid of the repeated code

    if (!self.embedded) {
        self.parentViewController.navigationItem.leftBarButtonItem = closeButton;
    }
    else {
        [self configureBackButtonWithGestureDelegate:nil];
    }
    NSMutableArray *rightBarItems = [NSMutableArray new];
    if(!(self.faqOptions.tags.count && self.tagsArray.count)){
        [rightBarItems addObject:searchBarButton];
    }
    if(self.faqOptions && self.faqOptions.showContactUsOnAppBar){
        [rightBarItems addObject:contactUsBarButton];
    }
    
    self.parentViewController.navigationItem.rightBarButtonItems = rightBarItems;
}

-(void)searchButtonAction:(id)sender{
    HLSearchViewController *searchViewController = [[HLSearchViewController alloc] init];
    [HLArticleUtil setFAQOptions:self.faqOptions andViewController:searchViewController];
    UINavigationController *navController = [[UINavigationController alloc]initWithRootViewController:searchViewController];
    [navController setModalPresentationStyle:UIModalPresentationCustom];
    [self.navigationController presentViewController:navController animated:NO completion:nil];
    
}

-(void)contactUsButtonAction:(id)sender{
    [[Hotline sharedInstance]showConversations:self];
}

-(void)updateCategories{
    [[KonotorDataManager sharedInstance] fetchAllCategoriesForTags:self.tagsArray withCompletion:^(NSArray *solutions, NSError *error) {
        if (!error) {
            self.categories = solutions;

            if(!self.categories.count){
                if(!self.emptyResultView){
                    
                    NSString *message;
                    if([[FDReachabilityManager sharedInstance] isReachable]){
                        message = HLLocalizedString(LOC_EMPTY_FAQ_TEXT);
                    }
                    else{
                        message = HLLocalizedString(LOC_OFFLINE_INTERNET_MESSAGE);
                        [self removeLoadingIndicator];
                    }
                    self.emptyResultView = [[HLEmptyResultView alloc]initWithImage:[self.theme getImageWithKey:IMAGE_FAQ_ICON] andText:message];
                    self.emptyResultView.translatesAutoresizingMaskIntoConstraints = NO;
                    [self.view addSubview:self.emptyResultView];
                    [FDAutolayoutHelper center:self.emptyResultView onView:self.view];
                }
            }
            else{
                self.emptyResultView.frame = CGRectZero;
                [self.emptyResultView removeFromSuperview];
                [self removeLoadingIndicator];
            }
          //  if (!self.faqOptions && !self.tagsArray.count){
                [self setNavigationItem];
          //  }
            [self.collectionView reloadData];
        }
    }];
}

-(void)removeLoadingIndicator{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicator removeFromSuperview];
    });
}

-(void)fetchUpdates{
    FDSolutionUpdater *updater = [[FDSolutionUpdater alloc]init];
    [[KonotorDataManager sharedInstance]areSolutionsEmpty:^(BOOL isEmpty) {
        if(isEmpty){
            [updater resetTime];
        }
        else {
            [self removeLoadingIndicator];
        }
        ShowNetworkActivityIndicator();
        [updater fetchWithCompletion:^(BOOL isFetchPerformed, NSError *error) {
            HideNetworkActivityIndicator();
            if(isEmpty){
                [self  removeLoadingIndicator];
            }
        }];
    }];
}

-(void)closeButton:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
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
        self.categories = @[];
        [self updateCategories];
        HideNetworkActivityIndicator();
    });
}

-(void)setupCollectionView{
    
    UICollectionViewFlowLayout* flowLayout = [[UICollectionViewFlowLayout alloc]init];
    self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    self.footerView = [[FDMarginalView alloc] initWithDelegate:self];
    
    [self.view addSubview:self.footerView];
    [self.view addSubview:self.collectionView];
    
    NSDictionary *views = @{ @"collectionView" : self.collectionView, @"footerView" : self.footerView};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[collectionView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[footerView]|" options:0 metrics:nil views:views]];
    if([self canDisplayFooterView]){
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[collectionView][footerView(40)]|" options:0 metrics:nil views:views]];
    }
    else {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[collectionView][footerView(0)]|" options:0 metrics:nil views:views]];
    }
    
    //Collection view subclass
    [self.collectionView registerClass:[HLGridViewCell class] forCellWithReuseIdentifier:@"FAQ_GRID_CELL"];
}

-(void)marginalView:(FDMarginalView *)marginalView handleTap:(id)sender{
    if(self.faqOptions.contactUsTags.count > 0){
        ConversationOptions *options = [ConversationOptions new];
        [options filterByTags:self.faqOptions.contactUsTags withTitle:self.faqOptions.contactUsTitle];
        [[Hotline sharedInstance] showConversations:self withOptions:options];
    }
    else{
        [[Hotline sharedInstance] showConversations:self];
    }
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

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HLGridViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"FAQ_GRID_CELL" forIndexPath:indexPath];
    if (!cell) {
        CGFloat cellSize = [UIScreen mainScreen].bounds.size.width/2;
        cell = [[HLGridViewCell alloc] initWithFrame:CGRectMake(0, 0, cellSize, cellSize)];
    }
    if (indexPath.row < self.categories.count){
        HLCategory *category = self.categories[indexPath.row];
        cell.label.text = category.title;
        cell.backgroundColor = [self.theme gridViewCellBackgroundColor];
        cell.layer.borderWidth=0.3f;
        cell.layer.borderColor=[self.theme gridViewCellBorderColor].CGColor;
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        if (!category.icon){
            cell.imageView.image = [FDCell generateImageForLabel:category.title];
        }else{
            cell.imageView.image = [UIImage imageWithData:category.icon];
        }
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (IS_IPAD) {
        return CGSizeMake( ([UIScreen mainScreen].bounds.size.width/3), ([UIScreen mainScreen].bounds.size.width/4));
    }
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        return CGSizeMake( ([UIScreen mainScreen].bounds.size.width/3), ([UIScreen mainScreen].bounds.size.height/2));
    }
    return CGSizeMake( ([UIScreen mainScreen].bounds.size.width/2), ([UIScreen mainScreen].bounds.size.height/4));
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row < self.categories.count) {
        HLCategory *category = self.categories[indexPath.row];
        HLArticlesController *articleController = [[HLArticlesController alloc] initWithCategory:category];
        [HLArticleUtil setFAQOptions:self.faqOptions andViewController:articleController];
        HLContainerController *container = [[HLContainerController alloc]initWithController:articleController andEmbed:NO];
        [self.navigationController pushViewController:container animated:YES];
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0f;
}

// Layout: Set Edges
- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0,0,0,0);  // top, left, bottom, right
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    [self setNavigationItem];
    [self.collectionView reloadData];
}

@end
