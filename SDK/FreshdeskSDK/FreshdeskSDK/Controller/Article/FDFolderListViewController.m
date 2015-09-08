//
//  FDFolderListViewController.m
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 29/04/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDArticle.h"
#import "FDFolder.h"
#import "MobiHelpDatabase.h"
#import "FDAPIClient.h"
#import "FDNewTicketViewController.h"
#import "FDCoreDataFetchManager.h"
#import "FDArticleListViewController.h"
#import "FDFolderListViewController.h"
#import "FDArticleDetailViewController.h"
#import "FDTicketListViewController.h"
#import "FDProgressHUD.h"
#import "FDFolderListHeaderView.h"
#import "FDDateUtil.h"
#import "FDFooterView.h"
#import "FDKit.h"
#import "FDSecureStore.h"
#import "FDConfigUpdater.h"
#import "FDTicketsUpdater.h"
#import "FDSolutionUpdater.h"
#import "FDMacros.h"
#import "MobihelpAppState.h"
#import "FDCoreDataCoordinator.h"
#import "FDArticleContent.h"

float HEADER_VIEW_HEIGHT = 44.0f;

#define FOLDER_CELL_REUSE_IDENTIFIER @"FolderCell"
#define SEARCH_CELL_REUSE_IDENTIFIER @"SearchCell"

@interface FDFolderListViewController () <CoreDataFetchManagerDelegate, UITableViewDelegate, UISearchBarDelegate>
@property (strong, nonatomic) FDTableView                *tableView;
@property (strong, nonatomic) FDSearchBar                *searchBar;
@property (strong, nonatomic) NSFetchedResultsController *fetchResultsController;
@property (strong, nonatomic) FDCoreDataFetchManager     *coreDataFetchManager;
@property (strong, nonatomic) FDTheme                    *theme;
@property (strong, nonatomic) FDFolderListHeaderView     *headerView;
@property (strong, nonatomic) FDFooterView               *footerView;
@property (strong, nonatomic) FDSecureStore              *secureStore;
@property (strong, nonatomic) UILabel                    *noSolutionsLabel;
@property (strong, nonatomic) NSIndexPath                *lastSelectedIP;
@property (strong, nonatomic) FDSolutionUpdater          *solutionsUpdater;
@property (strong, nonatomic) MobiHelpDatabase           *database;

@end

@implementation FDFolderListViewController
    
#pragma mark - Lazy Instantiations

-(MobiHelpDatabase *)database{
    if(!_database){
        _database = [[MobiHelpDatabase alloc] initWithContext:[[FDCoreDataCoordinator sharedInstance] mainContext]];
    }
    return _database;
}

-(FDTheme *)theme{
    if(!_theme) _theme = [FDTheme sharedInstance];
    return _theme;
}

-(FDSecureStore *)secureStore{
    if(!_secureStore){
        _secureStore = [FDSecureStore sharedInstance];
    }
    return _secureStore;
}

-(FDSolutionUpdater*)solutionsUpdater{
    if(!_solutionsUpdater){
        _solutionsUpdater = [[FDSolutionUpdater alloc]init];
    }
    return _solutionsUpdater;
}

- (void)setupTableViewConstraints {
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeading
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    if ([self.secureStore boolValueForKey:MOBIHELP_DEFAULTS_IS_PAID_USER]) {
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:0.0]];
    } else {
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:-20.0]];
    }
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView
                                                          attribute:NSLayoutAttributeTrailing
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTrailing
                                                         multiplier:1.0
                                                           constant:0.0]];
}

-(FDFolderListHeaderView *)headerView{
    if(!_headerView){
        float headerViewWidth      = self.view.frame.size.width;
        float headerViewHeight     = HEADER_VIEW_HEIGHT;
        CGRect headerViewFrame     = CGRectMake(0, 0, headerViewWidth, headerViewHeight);
        _headerView = [[FDFolderListHeaderView alloc]initWithFrame:headerViewFrame];
        [_headerView tapGestureHander:@selector(showTicketListViewController:) onController:self];
    }
    return _headerView;
}

- (void)showTicketListViewController:(id)sender {
    FDTicketListViewController *ticketListController = [[FDTicketListViewController alloc]init];
    [self.navigationController pushViewController:ticketListController animated:YES];
}

-(NSFetchedResultsController *)fetchResultsController{
    if(!_fetchResultsController){
        NSFetchRequest *request            = [NSFetchRequest fetchRequestWithEntityName:MOBIHELP_DB_FOLDER_ENTITY];
        NSSortDescriptor *folderPosition   = [NSSortDescriptor sortDescriptorWithKey:@"position" ascending:YES];
        NSSortDescriptor *categoryPosition = [NSSortDescriptor sortDescriptorWithKey:@"categoryPosition" ascending:YES];
        request.sortDescriptors            = @[categoryPosition, folderPosition];
        request.fetchBatchSize             = 20;
        _fetchResultsController = [[NSFetchedResultsController alloc]
                                   initWithFetchRequest:request managedObjectContext:self.database.context
                                   sectionNameKeyPath:@"categoryPosition" cacheName:nil];
    }
    return _fetchResultsController;
}

- (void)handleEmptySolutionsScenario {
    self.noSolutionsLabel = [[UILabel alloc] init];
    self.noSolutionsLabel.backgroundColor = [UIColor clearColor];
    self.noSolutionsLabel.numberOfLines = 0;
    self.noSolutionsLabel.textAlignment = NSTextAlignmentCenter;
    self.noSolutionsLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.noSolutionsLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14.0f];
    self.noSolutionsLabel.textColor = [self.theme noItemsFoundMessageColor];
    [self.noSolutionsLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.noSolutionsLabel.text = FDLocalizedString(@"No Folders Message" );
    [self.view addSubview:self.noSolutionsLabel];
    self.noSolutionsLabel.hidden = YES;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.noSolutionsLabel
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:150.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.noSolutionsLabel
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeading
                                                         multiplier:1.0
                                                           constant:20.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.noSolutionsLabel
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                         multiplier:1.0
                                                           constant:100.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.noSolutionsLabel
                                                          attribute:NSLayoutAttributeTrailing
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTrailing
                                                         multiplier:1.0
                                                           constant:-20.0]];
}

#pragma mark - View Controller Initialization
- (void)viewDidLoad{
    [super viewDidLoad];
    [self setupSubviews];
    [self adjustUIBounds];
    [self setDataSource];
    [self setNavigationItem];
    [self handleEmptySolutionsScenario];
    [self localNotificationSubscription];
    [self theming];
    [self addFooterView];
}

-(void)setupSubviews{
    [self setupTableView];
    [self setupSearchBar];
}

-(void)setupTableView{
    self.tableView = [[FDTableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.tableView];
    [self setupTableViewConstraints];
}

-(void)setupSearchBar{
    self.searchBar = [[FDSearchBar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = FDLocalizedString(@"Search Placeholder");
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

-(void)viewWillLayoutSubviews{
    self.searchBar.frame= CGRectMake(0, 0, self.view.frame.size.width, 44);
}

-(void)theming{
    [self.searchDisplayController.searchResultsTableView setBackgroundColor:[self.theme backgroundColorSDK]];
}

-(void)localNotificationSubscription{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noSolutions:) name:@"MobiHelp_NoSolutions" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(solutionsExist:) name:@"MobiHelp_SolutionsExist" object:nil];
}

- (void)noSolutions:(NSNotification *)note {
    self.noSolutionsLabel.hidden = NO;
}

- (void)solutionsExist:(NSNotification *)note {
    self.noSolutionsLabel.hidden = YES;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self fetchUpdates];
    [self.tableView reloadData];
    [self.tableView deselectRowAtIndexPath:self.lastSelectedIP animated:NO];
    [self setupConversationCell];
}

-(void)setupConversationCell{
    BOOL isTicketEmpty = [self.database isTicketEmpty];
    BOOL isAppDeleted  = [self.secureStore boolValueForKey:MOBIHELP_DEFAULTS_IS_APP_DELETED];
    if (!isTicketEmpty && !isAppDeleted) {
        if (![self.secureStore boolValueForKey:MOBIHELP_DEFAULTS_IS_CONVERSATIONS_DISABLED]) {
                self.tableView.tableHeaderView = self.headerView;
        }
    }
}

-(void)addFooterView {
    self.footerView = [[FDFooterView alloc]initWithController:self];
    [self.view addSubview:self.footerView];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    HideNetworkActivityIndicator();
    [FDProgressHUD dismiss];
}

#pragma mark - Navigation Stack

-(void)setNavigationItem{
    [self.navigationItem setTitle:FDLocalizedString(@"Main Support View Nav Bar Title Text" )];
    
    //Left Bar Button Item
    FDBarButtonItem *closeButton = [[FDBarButtonItem alloc]initWithTitle:FDLocalizedString(@"Close Button Text" ) style:UIBarButtonItemStylePlain target:self action:@selector(closeButton:)];
    [self.navigationItem setLeftBarButtonItem:closeButton];
    
    //Right Bar Button Item
    UIImage *searchButtonImage = [self.theme getThemedImageFromMHBundleWithName:MOBIHELP_IMAGE_NAV_BAR_SEARCH_BUTTON];
    UIImage *composeButtonImage = [self.theme getThemedImageFromMHBundleWithName:MOBIHELP_IMAGE_NAV_BAR_COMPOSE_BUTTON];
    
    FDBarButtonItem *searchButton = [[FDBarButtonItem alloc] initWithImage:searchButtonImage style:UIBarButtonItemStylePlain target:self action:@selector(searchButtonAction:)];
    
    FDBarButtonItem *flexibleItem = [[FDBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    flexibleItem.width = -12.0f;
    
    FDBarButtonItem *createNewTicketButton = [[FDBarButtonItem alloc] initWithImage:composeButtonImage style:UIBarButtonItemStylePlain target:self action:@selector(createNewTicketButtonAction:)];
    
    searchButton.imageInsets = UIEdgeInsetsMake(0, 0, 0, -25);
    createNewTicketButton.imageInsets = UIEdgeInsetsMake(0, -25, 0, 0);
    
    if ([self.secureStore boolValueForKey:MOBIHELP_DEFAULTS_IS_CONVERSATIONS_DISABLED]) {
            searchButton.imageInsets = UIEdgeInsetsMake(0, 0, 0, 5);
            self.navigationItem.rightBarButtonItems = @[searchButton];
    }else
    {
            self.navigationItem.rightBarButtonItems = @[flexibleItem,createNewTicketButton,searchButton];
    }
}

-(void)createNewTicketButtonAction:(id)sender{
    BOOL isAppValid = [[MobihelpAppState sharedMobihelpAppState] isAppDisabled];
    if (isAppValid) {
        FDNewTicketViewController *newTicketViewController = [[FDNewTicketViewController alloc]initWithModalPresentationType:NO];
        newTicketViewController.sourceController = self;
        [self.navigationController pushViewController:newTicketViewController animated:YES];
    }else{
        [FDProgressHUD showErrorWithStatus:FDLocalizedString(@"app disabled error message")];
    }
}

-(void)searchButtonAction:(id)sender{
    self.searchBar.hidden = NO;
    [self.searchBar becomeFirstResponder];
    [self.searchDisplayController setActive:YES animated:YES];
}

-(void)closeButton:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Set Data Source

-(void)setDataSource{
    [self setUpCoreDataFetch];
}

-(void)adjustUIBounds{
    self.edgesForExtendedLayout=UIRectEdgeNone;
    self.navigationController.view.backgroundColor = [self.theme searchBarOuterBackgroundColor];
}

-(void)setUpCoreDataFetch{
    self.coreDataFetchManager = [[FDCoreDataFetchManager alloc]initWithSearchBar:self.searchBar withContentsController:self andTableView:self.tableView];
    self.coreDataFetchManager.fetchedResultsController = self.fetchResultsController;
    self.coreDataFetchManager.delegate                 = self;
}

-(id)fetchManager:(id)manager cellForTableView:(UITableView *)tableView withObject:(id)object {
    NSString *cellIdentifier = FOLDER_CELL_REUSE_IDENTIFIER;
    FDTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[FDTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    FDFolder *folder = object;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [cell.textLabel sizeToFit];
    cell.textLabel.text = folder.name;
    return cell;
}

-(id)fetchManager:(FDCoreDataFetchManager *)manager cellForSearchTableView:(UITableView *)tableView withObject:(id)object {
    NSString *cellIdentifier = SEARCH_CELL_REUSE_IDENTIFIER;
    FDTableViewCell *cell    = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[FDTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    FDArticleContent *article    = object;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [cell.textLabel sizeToFit];
    cell.textLabel.text = article.title;
    return cell;
}
    
-(NSFetchRequest *)fetchRequestForSearchTerm:(NSString *)term{
    NSFetchRequest *request   = [[NSFetchRequest alloc]initWithEntityName:MOBIHELP_DB_ARTICLE_ENTITY];
    NSPredicate *searchFilter = [NSPredicate predicateWithFormat:@"title contains[cd] %@",term];
    request.predicate         = searchFilter;
    return request;
}

#pragma mark - Set Web Service

-(void)fetchUpdates{
    [self fetchAppConfig];
    [self fetchSolutionsAndTickets];
}

-(void)fetchAppConfig{
    [[[FDConfigUpdater alloc] init] fetchWithCompletion:^(NSError *error) { /* http://goo.gl/4Ic212 */ }];
}

-(void)fetchSolutionsAndTickets{
    BOOL isAppValid = [[MobihelpAppState sharedMobihelpAppState] isAppDisabled];
    if (isAppValid) {
        [self updateSolutions];
        [self updateTicketsAndNotes];
    }
}

-(void)updateSolutions{
    BOOL isFolderEmpty = [self.database isFolderEmpty];
    if(isFolderEmpty){
        [self.solutionsUpdater resetTime];
    }
    ShowNetworkActivityIndicator();
    [self.solutionsUpdater fetchWithCompletion:^(NSError *error) {
        HideNetworkActivityIndicator();
        if (error) {
            FDLog(@"Warning: Solutions could not be fetched because: %@",error);
        }
        self.noSolutionsLabel.hidden = ![self.database isFolderEmpty];
    }];
}

-(void)updateTicketsAndNotes{
    [[[FDTicketsUpdater alloc]init] fetchWithCompletion:^(NSError *error) {
        [self updateUnreadNotesCount];
    }];
}

-(void)updateUnreadNotesCount{
    MobiHelpDatabase *database = [[MobiHelpDatabase alloc] initWithContext:[[FDCoreDataCoordinator sharedInstance] getBackgroundContext]];
    [database.context performBlock:^{
        NSInteger updatedNotes = [database getOverallUnreadNotesCount];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.headerView updateBadgeButtonCount:updatedNotes];
        });
    }];
}

#pragma mark - Table View Delegates

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    _lastSelectedIP = indexPath;
    if (tableView == self.tableView) {
        FDArticleListViewController *articlesListController = [[FDArticleListViewController alloc]init];
        FDFolder *folder = [self.fetchResultsController objectAtIndexPath:indexPath];
        articlesListController.articleFolder = folder;
        [self.navigationController pushViewController:articlesListController animated:YES];
    }else{
        FDArticleDetailViewController *articlesDetailController = [[FDArticleDetailViewController alloc]init];
        FDArticleContent *article = [self.coreDataFetchManager.searchResults objectAtIndex:indexPath.row];
        articlesDetailController.articleDescription = article.articleDescription;
        [self.navigationController pushViewController:articlesDetailController animated:YES];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    if (tableView == self.tableView) {
        
        NSString *title = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];

        UIView *sectionHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, [self.theme tableViewSectionHeaderHeight])];
        sectionHeaderView.backgroundColor = [self.theme tableViewSectionHeaderBackgroundColor];
        
        UILabel *sectionHeaderTitle = [[UILabel alloc] init];
        
        UIFont *headerFont = [UIFont fontWithName:[self.theme tableViewSectionHeaderFontName] size:[self.theme tableViewSectionFontSize]];
        
        CGSize ratingMessageSize = [self messageSize:title forFont:headerFont];
        sectionHeaderTitle.frame = CGRectMake(10, ([self.theme tableViewSectionHeaderHeight] - ratingMessageSize.height)/2, ratingMessageSize.width, ratingMessageSize.height);
        
        sectionHeaderTitle.text = title;
        sectionHeaderTitle.textColor = [self.theme tableViewSectionHeaderFontColor];
        sectionHeaderTitle.backgroundColor = [UIColor clearColor];
        sectionHeaderTitle.font = [UIFont fontWithName:[self.theme tableViewSectionHeaderFontName] size:[self.theme tableViewSectionFontSize]];
        
        [sectionHeaderView addSubview:sectionHeaderTitle];
        
        return sectionHeaderView;
    }
    
    else {
        return nil;
    }
}

-(CGSize)messageSize:(NSString*)message forFont:(UIFont *)messageFont{
    
    NSDictionary *preferredAttributes = @{
                                          NSFontAttributeName:[UIFont fontWithName:messageFont.fontName size:messageFont.pointSize]
                                          };
    return [message boundingRectWithSize:CGSizeMake(self.view.bounds.size.width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:preferredAttributes context:nil].size;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    if (tableView == self.tableView) {
        return [self.theme tableViewSectionHeaderHeight];
    }
    
    else {
        return 0.0f;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellText;
    if ([tableView isKindOfClass:[FDTableView class]]) {
        FDFolder *folder = [self.fetchResultsController objectAtIndexPath:indexPath];
        cellText = folder.name;
    }else {
        FDArticleContent *article = self.coreDataFetchManager.searchResults[indexPath.row];
        cellText = article.title;
    }

    UIFont *cellFont = [UIFont fontWithName:[self.theme tableViewCellFontName] size:[self.theme tableViewCellFontSize]];
    CGSize labelSize = CGSizeZero;
    if (cellText) {
        NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:cellText attributes:@{NSFontAttributeName:cellFont}];
        CGRect rect = [attributedText boundingRectWithSize:(CGSize){[UIScreen mainScreen].bounds.size.width - 40, CGFLOAT_MAX} options:NSStringDrawingUsesLineFragmentOrigin context:nil];
        labelSize = rect.size;
    }
    return labelSize.height + 30;
}

#pragma mark - search bar delegate

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    self.searchBar.hidden = YES;
}

@end