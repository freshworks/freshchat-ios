//
//  HLCategoriesListController.m
//  
//
//  Created by Aravinth Chandran on 23/09/15.
//
//

#import "HLCategoriesListController.h"
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

@interface HLCategoriesListController ()

@property (nonatomic, strong)NSArray *categories;
@property (nonatomic, strong)HLTheme *theme;
@property (nonatomic, strong) HLEmptyResultView *emptyResultView;

@end

@implementation HLCategoriesListController

-(void)willMoveToParentViewController:(UIViewController *)parent{
    self.theme = [HLTheme sharedInstance];
    [super willMoveToParentViewController:parent];
    parent.navigationItem.title = HLLocalizedString(LOC_FAQ_TITLE_TEXT);
    [self setNavigationItem];
    [self updateCategories];
    [self localNotificationSubscription];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self fetchUpdates];
}

-(void)updateCategories{
    [[KonotorDataManager sharedInstance]fetchAllSolutions:^(NSArray *solutions, NSError *error) {
        if (!error) {
            self.categories = solutions;
            [self setNavigationItem];
            [self.tableView reloadData];
        }
    }];
}

-(void)setNavigationItem{
    
    UIBarButtonItem *contactUsBarButton = [[FDBarButtonItem alloc] initWithImage:[self.theme getImageWithKey:IMAGE_CONTACT_US_ICON]
                                                                           style:UIBarButtonItemStylePlain target:self action:@selector(contactUsButtonAction:)];
    UIBarButtonItem *searchBarButton = [[FDBarButtonItem alloc] initWithImage:[self.theme getImageWithKey:IMAGE_SEARCH_ICON]
                                                                           style:UIBarButtonItemStylePlain target:self action:@selector(searchButtonAction:)];
    
    UIBarButtonItem *closeButton = [[FDBarButtonItem alloc]initWithTitle:HLLocalizedString(LOC_FAQ_CLOSE_BUTTON_TEXT) style:UIBarButtonItemStylePlain target:self action:@selector(closeButton:)];
    
    if (!self.embedded) {
        self.parentViewController.navigationItem.leftBarButtonItem = closeButton;
    }
    else {
        [self configureBackButtonWithGestureDelegate:nil];
    }
    NSArray *rightBarItems;
    if(!self.categories.count){
        rightBarItems = @[contactUsBarButton];
    }
    else{
        rightBarItems = @[searchBarButton,contactUsBarButton];
    }
    self.parentViewController.navigationItem.rightBarButtonItems = rightBarItems;
}

-(void)closeButton:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)searchButtonAction:(id)sender{
    HLSearchViewController *searchViewController = [[HLSearchViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc]initWithRootViewController:searchViewController];
    [navController setModalPresentationStyle:UIModalPresentationCustom];
    [self presentViewController:navController animated:NO completion:nil];
}

-(void)contactUsButtonAction:(id)sender{
    [[Hotline sharedInstance]showConversations:self];
}

-(void)localNotificationSubscription{
    __weak typeof(self)weakSelf = self;
    [[NSNotificationCenter defaultCenter]addObserverForName:HOTLINE_SOLUTIONS_UPDATED object:nil queue:nil usingBlock:^(NSNotification *note) {
        HideNetworkActivityIndicator();
        [weakSelf updateCategories];
    }];
}

-(void)fetchUpdates{
    FDSolutionUpdater *updater = [[FDSolutionUpdater alloc]init];
    [[KonotorDataManager sharedInstance]areSolutionsEmpty:^(BOOL isEmpty) {
        if(isEmpty){
            
            [updater resetTime];
            self.emptyResultView = [[HLEmptyResultView alloc]initWithImage:[self.theme getImageWithKey:IMAGE_FAQ_ICON] andText:HLLocalizedString(LOC_EMPTY_FAQ_TEXT)];
            self.emptyResultView.translatesAutoresizingMaskIntoConstraints = NO;
            [self.view addSubview:self.emptyResultView];
            
            [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.emptyResultView
                                                                  attribute:NSLayoutAttributeCenterX
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.tableView
                                                                  attribute:NSLayoutAttributeCenterX
                                                                 multiplier:1.0
                                                                   constant:0.0]];
            
            [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.emptyResultView
                                                                  attribute:NSLayoutAttributeCenterY
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.tableView
                                                                  attribute:NSLayoutAttributeCenterY
                                                                 multiplier:1.0
                                                                   constant:0.0]];
            
        }
        else{
            [self.emptyResultView removeFromSuperview];
        }
        
        ShowNetworkActivityIndicator();
        [updater fetchWithCompletion:^(BOOL isFetchPerformed, NSError *error) {
            if (!isFetchPerformed) HideNetworkActivityIndicator();
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
    HLContainerController *container = [[HLContainerController alloc]initWithController:articleController andEmbed:NO];
    [self.navigationController pushViewController:container animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 64;
}

@end