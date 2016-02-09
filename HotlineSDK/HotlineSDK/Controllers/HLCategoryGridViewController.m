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

@interface HLCategoryGridViewController () <UIScrollViewDelegate,UISearchBarDelegate,FDMarginalViewDelegate>

@property (nonatomic, strong) NSArray *categories;
@property (nonatomic, strong) FDSearchBar *searchBar;
@property (nonatomic, strong) FDMarginalView *footerView;
@property (nonatomic, strong) UILabel  *noSolutionsLabel;
@property (nonatomic, strong) HLTheme *theme;
@property (strong, nonatomic) UIImageView *emptyFAQImgView;
@property (strong, nonatomic) UILabel *emptyFAQLbl;

@end

@implementation HLCategoryGridViewController

-(void)willMoveToParentViewController:(UIViewController *)parent{
    parent.title = HLLocalizedString(LOC_FAQ_TITLE_TEXT);
    self.theme = [HLTheme sharedInstance];
    self.view.backgroundColor = [UIColor whiteColor];
    [self updateCategories];
    [self setupSubviews];
    [self adjustUIBounds];
    [self setNavigationItem];
    [self theming];
    [self localNotificationSubscription];
}

-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
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
    UIImage *searchButtonImage = [self.theme getImageWithKey:IMAGE_SEARCH_ICON];
    UIImage *contactUsButtonImage = [self.theme getImageWithKey:IMAGE_CONTACT_US_ICON];
    
    UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    searchButton.frame = CGRectMake(0, 0, 44, 44);
    [searchButton setImage:searchButtonImage forState:UIControlStateNormal];
    [searchButton addTarget:self action:@selector(searchButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *searchBarButton = [[UIBarButtonItem alloc] initWithCustomView:searchButton];
    
    UIBarButtonItem *fixedItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedItem.width = -20.0f; // or whatever you want
    
    UIButton *contactUsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    contactUsButton.frame = CGRectMake(272, 50, 24, 24);
    [contactUsButton setImage:contactUsButtonImage forState:UIControlStateNormal];
    [contactUsButton addTarget:self action:@selector(contactUsButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *contactUsBarButton = [[UIBarButtonItem alloc] initWithCustomView:contactUsButton];
    
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc]initWithTitle:HLLocalizedString(LOC_FAQ_CLOSE_BUTTON_TEXT) style:UIBarButtonItemStylePlain target:self action:@selector(closeButton:)];
    
    //TODO: Need to revisit this to get rid of the repeated code
    BOOL isEmbeddable = ((HLContainerController *)self.parentViewController).isEmbeddable;
    if (!isEmbeddable) {
        self.parentViewController.navigationItem.leftBarButtonItem = closeButton;
    }
    
    self.parentViewController.navigationItem.rightBarButtonItems = @[fixedItem,searchBarButton,contactUsBarButton];
    
    self.searchDisplayController.displaysSearchBarInNavigationBar = YES;
}

-(void)searchButtonAction:(id)sender{
    HLSearchViewController *searchViewController = [[HLSearchViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc]initWithRootViewController:searchViewController];
    [navController setModalPresentationStyle:UIModalPresentationCustom];
    [self.navigationController presentViewController:navController animated:NO completion:nil];
    
}

-(void)contactUsButtonAction:(id)sender{
    [[Hotline sharedInstance]presentFeedback:self];
}

-(void)updateCategories{
    [[KonotorDataManager sharedInstance]fetchAllSolutions:^(NSArray *solutions, NSError *error) {
        if (!error) {
            self.categories = solutions;

            if(!self.categories.count){
                
                self.emptyFAQImgView = [[UIImageView alloc] init];
                self.emptyFAQImgView.image = [self.theme getImageWithKey:IMAGE_FAQ_ICON];
                [self.emptyFAQImgView setTranslatesAutoresizingMaskIntoConstraints:NO];
                [self.view addSubview:self.emptyFAQImgView];
                
                self.emptyFAQLbl = [[UILabel alloc]init];
                self.emptyFAQLbl.translatesAutoresizingMaskIntoConstraints = NO;
                self.emptyFAQLbl.textColor = [self.theme dialogueTitleTextColor];
                self.emptyFAQLbl.font = [self.theme dialogueTitleFont];
                self.emptyFAQLbl.lineBreakMode = NSLineBreakByWordWrapping;
                self.emptyFAQLbl.numberOfLines = 2;
                self.emptyFAQLbl.textAlignment= NSTextAlignmentCenter;
                self.emptyFAQLbl.text = HLLocalizedString(LOC_EMPTY_FAQ_TEXT);
                [self.view addSubview:self.emptyFAQLbl];
                
                [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.emptyFAQImgView
                                                                      attribute:NSLayoutAttributeCenterX
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.collectionView
                                                                      attribute:NSLayoutAttributeCenterX
                                                                     multiplier:1.0
                                                                       constant:0.0]];
                
                [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.emptyFAQImgView
                                                                      attribute:NSLayoutAttributeCenterY
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.collectionView
                                                                      attribute:NSLayoutAttributeCenterY
                                                                     multiplier:1.0
                                                                       constant:0.0]];
                
                NSDictionary *emptychannelViews = @{@"emptyFAQImg":self.emptyFAQImgView, @"emptyFAQLbl" : self.emptyFAQLbl};
                
                [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-50-[emptyFAQLbl]-50-|" options:0 metrics:nil views:emptychannelViews]];
                
                [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[emptyFAQImg]-10-[emptyFAQLbl]" options:0 metrics:nil views:emptychannelViews]];
            }
            else{
                [self.emptyFAQImgView removeFromSuperview];
                [self.emptyFAQLbl removeFromSuperview];
            }
            
            [self.collectionView reloadData];
        }
    }];
}

-(void)fetchUpdates{
    FDSolutionUpdater *updater = [[FDSolutionUpdater alloc]init];
    [[KonotorDataManager sharedInstance]areSolutionsEmpty:^(BOOL isEmpty) {
        if(isEmpty) [updater resetTime];
        ShowNetworkActivityIndicator();
        [updater fetchWithCompletion:^(BOOL isFetchPerformed, NSError *error) {
            if (!isFetchPerformed) HideNetworkActivityIndicator();
        }];
    }];
}

-(void)closeButton:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)localNotificationSubscription{
    __weak typeof(self)weakSelf = self;
    [[NSNotificationCenter defaultCenter]addObserverForName:HOTLINE_SOLUTIONS_UPDATED object:nil queue:nil usingBlock:^(NSNotification *note) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.categories = @[];
            [weakSelf updateCategories];
            HideNetworkActivityIndicator();
        });
    }];
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
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[collectionView][footerView(40)]|" options:0 metrics:nil views:views]];
    
    //Collection view subclass
    [self.collectionView registerClass:[HLGridViewCell class] forCellWithReuseIdentifier:@"FAQ_GRID_CELL"];
}

-(void)marginalView:(FDMarginalView *)marginalView handleTap:(id)sender{
    [[Hotline sharedInstance]presentFeedback:self];
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
        cell.backgroundColor = [self.theme itemBackgroundColor];
        cell.layer.borderWidth=0.3f;
        cell.layer.borderColor=[self.theme itemSeparatorColor].CGColor;
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        if (!category.icon){
            //TODO: Add placeholder image
            cell.imageView.image = nil;
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
        HLContainerController *container = [[HLContainerController alloc]initWithController:articleController];
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
    [self.collectionView reloadData];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end