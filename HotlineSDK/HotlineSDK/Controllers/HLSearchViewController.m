//
//  FDCoreDataFetchManager.m
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 29/04/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "HLSearchViewController.h"
#import "FDUtilities.h"
#import "FDSecureStore.h"
#import "HLMacros.h"
#import "FDRanking.h"
#import "HLTheme.h"
#import "KonotorDataManager.h"
#import "FDButton.h"
#import "HLArticleDetailViewController.h"
#import "FDTableViewCell.h"
#import "FDArticleContent.h"
#import "FDSearchBar.h"
#import "HLContainerController.h"
#import "HLListViewController.h"
#import "Hotline.h"
#import "HLLocalization.h"

#import "FDArticleListCell.h"

#define SEARCH_CELL_REUSE_IDENTIFIER @"SearchCell"
#define SEARCH_BAR_HEIGHT 44

@interface  HLSearchViewController () <UISearchDisplayDelegate,UISearchBarDelegate,UIGestureRecognizerDelegate,UIScrollViewDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) UIView *trialView;
@property (strong, nonatomic) UITapGestureRecognizer *recognizer;
@property (strong, nonatomic) HLTheme *theme;
@property (strong, nonatomic) UIImageView *emptySearchImgView;
@property (strong, nonatomic) UILabel *emptyResultLbl;
@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic) BOOL isKeyboardOpen;
@end

@implementation HLSearchViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    [self setupSubviews];
    
    [self setupTap];
    self.view.userInteractionEnabled=YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

-(HLTheme *)theme{
    if(!_theme) _theme = [HLTheme sharedInstance];
    return _theme;
}
-(void)viewWillAppear:(BOOL)animated{
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

-(void)viewWillDisappear:(BOOL)animated{
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

-(void)setupTap{
    self.recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBehind:)];
    [self.recognizer setNumberOfTapsRequired:1];
    if(self.searchResults.count == 0){
        [self.view addGestureRecognizer:self.recognizer];
    }
}

- (void)handleTapBehind:(UITapGestureRecognizer *)sender{
    if (sender.state == UIGestureRecognizerStateEnded){
        if (self.searchResults.count == 0) {
            CGPoint location = [sender locationInView:nil]; //Passing nil gives us coordinates in the window
            UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
            CGPoint pointInSubview = [self.view convertPoint:location fromView:mainWindow];
            if (!CGRectContainsPoint(self.searchBar.bounds, pointInSubview)) {
                // Remove the recognizer first so it's view.window is valid.
                [self.view removeGestureRecognizer:sender];
                [self dismissModalViewControllerAnimated:YES];
            }
        }
    }
}

-(void)setupSubviews{
    self.searchBar = [[FDSearchBar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, SEARCH_BAR_HEIGHT)];
    self.searchBar.hidden = NO;
    self.searchBar.delegate = self;
    self.searchBar.placeholder = HLLocalizedString(LOC_SEARCH_PLACEHOLDER_TEXT);
    self.searchBar.showsCancelButton = YES;
    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.searchBar becomeFirstResponder];
    
    UIView *mainSubView = [self.searchBar.subviews lastObject];
    for (id subview in mainSubView.subviews) {
        if ([subview isKindOfClass:[UITextField class]]) {
            UITextField *textField = (UITextField *)subview;
            textField.backgroundColor = [[HLTheme sharedInstance] searchBarInnerBackgroundColor];
        }
    }
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
    self.tableView.translatesAutoresizingMaskIntoConstraints=NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    if([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)])
    {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    [self.view addSubview:self.tableView];
    
    self.tableView.contentInset = UIEdgeInsetsMake(-(SEARCH_BAR_HEIGHT/2), 0, SEARCH_BAR_HEIGHT, 0);
    
    [self setEmptySearchResultView];

    [self.view addSubview:self.searchBar];
    
    NSDictionary *views = @{ @"top":self.topLayoutGuide,@"searchBar" : self.searchBar,@"trial":self.tableView};
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[searchBar]|"
                                                                      options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[trial]|"
                                                                      options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[top][searchBar][trial]|"
                                                                      options:0 metrics:nil views:views]];
}

- (void) setEmptySearchResultView{
    
    self.emptySearchImgView = [[UIImageView alloc] init];
    self.emptySearchImgView.image = [self.theme getImageWithKey:@"EmptySearchImage"];
    [self.emptySearchImgView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.emptySearchImgView];
    
    HLTheme *theme = [HLTheme sharedInstance];
    self.emptyResultLbl = [[UILabel alloc]init];
    self.emptyResultLbl.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptyResultLbl.textColor = [theme dialogueTitleTextColor];
    self.emptyResultLbl.font = [theme dialogueTitleFont];
    self.emptyResultLbl.lineBreakMode = NSLineBreakByWordWrapping;
    self.emptyResultLbl.numberOfLines = 2;
    self.emptyResultLbl.textAlignment= NSTextAlignmentCenter;
    self.emptyResultLbl.text = HLLocalizedString(LOC_SEARCH_EMPTY_RESULT_TEXT);
    [self.view addSubview:self.emptyResultLbl];
    
    NSDictionary *emptySubViews = @{@"searchBar":self.searchBar ,@"emptySearchImageView":self.emptySearchImgView, @"emptyLabel":self.emptyResultLbl};
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-50-[emptyLabel]-50-|" options:0 metrics:nil views:emptySubViews]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[emptySearchImageView(100)]" options:0 metrics:nil views:emptySubViews]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[emptySearchImageView(100)]-10-[emptyLabel]" options:0 metrics:nil views:emptySubViews]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.emptySearchImgView
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.emptyResultLbl
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.emptySearchImgView
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:0.5
                                                           constant:0.0]];
    
    self.emptySearchImgView.hidden = YES;
    self.emptyResultLbl.hidden = YES;
}

- (void) showEmptySearchView{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.emptySearchImgView.hidden = NO;
        self.emptyResultLbl.hidden = NO;
    });
}

- (void) hideEmptySearchView{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.emptySearchImgView.hidden = YES;
        self.emptyResultLbl.hidden = YES;
    });
}

#pragma mark Keyboard delegate

-(void) keyboardWillShow:(NSNotification *)note{
    NSTimeInterval animationDuration = [[note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    self.isKeyboardOpen = YES;
    CGRect keyboardFrame = [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardRect = [self.view convertRect:keyboardFrame fromView:nil];
    CGFloat keyboardCoveredHeight = self.view.bounds.size.height - keyboardRect.origin.y;
    self.keyboardHeight = keyboardCoveredHeight;
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}

-(void) keyboardWillHide:(NSNotification *)note{
    self.isKeyboardOpen = NO;
    NSTimeInterval animationDuration = [[note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    self.keyboardHeight = 0.0;
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}


#pragma mark - TableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)sectionIndex{
    return self.searchResults.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = SEARCH_CELL_REUSE_IDENTIFIER;
    FDArticleListCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[FDArticleListCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.textLabel.numberOfLines = 3;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    }
    if (indexPath.row < self.searchResults.count) {
        FDArticleContent *article = self.searchResults[indexPath.row];
        [cell.textLabel sizeToFit];
        cell.articleText.text = article.title;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UIFont *cellFont = [self.theme tableViewCellFont];
    HLArticle *searchArticle = self.searchResults[indexPath.row];
    NSAttributedString *title = [[NSAttributedString alloc] initWithString:searchArticle.title attributes:@{NSFontAttributeName:cellFont}];
    CGFloat heightOfcell = [HLListViewController heightOfCell:title];
    return heightOfcell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row < self.searchResults.count) {
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        HLArticleDetailViewController *articlesDetailController = [[HLArticleDetailViewController alloc]init];
        FDArticleContent *article = self.searchResults[indexPath.row];
        articlesDetailController.articleDescription = article.articleDescription;
        articlesDetailController.articleID = article.articleID;
        articlesDetailController.articleTitle = article.title;
        articlesDetailController.isFromSearchView = TRUE;
        HLContainerController *containerController = [[HLContainerController alloc]initWithController:articlesDetailController andEmbed:NO];
        [self.navigationController pushViewController:containerController animated:YES];
    }
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

-(void)filterArticlesForSearchTerm:(NSString *)term{
    if (term.length > 2){
        term = [FDUtilities replaceSpecialCharacters:term with:@""];
        NSManagedObjectContext *context = [KonotorDataManager sharedInstance].backgroundContext ;
        [context performBlock:^{
            NSArray *articles = [FDRanking rankTheArticleForSearchTerm:term withContext:context];
            if ([articles count] > 0) {
                [self hideEmptySearchView];
                self.searchResults = articles;
                [self reloadSearchResults];
            }else{
                
                self.searchResults = nil;
                [self showEmptySearchView];
                [self reloadSearchResults];
            }
        }];
    }else{
        [self hideEmptySearchView];
        [self fetchAllArticles];
    }
}

-(void)fetchAllArticles{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_ARTICLE_ENTITY];
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].mainObjectContext;
    [context performBlock:^{
        self.searchResults = [context executeFetchRequest:request error:nil];
        [self reloadSearchResults];
    }];
}

-(void)reloadSearchResults{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

-(void)viewWillLayoutSubviews{
    self.searchBar.frame = CGRectMake(0, 0, self.view.frame.size.width, 44);
}


-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    [self dismissModalViewControllerAnimated:NO];
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    NSInteger searchStringLength = searchText.length;
    if (searchStringLength!=0) {
        self.tableView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:1.0];
        [self filterArticlesForSearchTerm:searchText];
        [self.view removeGestureRecognizer:self.recognizer];
    }else{
        [self.view addGestureRecognizer:self.recognizer];
        self.tableView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
        self.searchResults = nil;
        [self hideEmptySearchView];
        [self.tableView reloadData];
    }
}

-(void)marginalView:(FDMarginalView *)marginalView handleTap:(id)sender{
    [[Hotline sharedInstance]presentConversations:self];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [self.view endEditing:YES]; 
}

-(void)localNotificationUnSubscription{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)dealloc{
    [self localNotificationUnSubscription];
}

@end