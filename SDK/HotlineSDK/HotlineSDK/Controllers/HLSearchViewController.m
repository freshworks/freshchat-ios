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
#import "KonotorFeedbackScreen.h"
#import "FDButton.h"
#import "HLArticleDetailViewController.h"
#import "FDTableViewCell.h"
#import "FDArticleContent.h"
#import "FDSearchBar.h"

#define SEARCH_CELL_REUSE_IDENTIFIER @"SearchCell"

@interface  HLSearchViewController () <UISearchDisplayDelegate,UISearchBarDelegate,UIGestureRecognizerDelegate,UIScrollViewDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) UIView *trialView;
@property (strong,nonatomic) UITapGestureRecognizer *recognizer;
@end

@implementation HLSearchViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    [self setupSubviews];
}

-(void)viewWillAppear:(BOOL)animated{
    [self checkNavigationBar];
    [self setupTap];
    self.view.userInteractionEnabled=YES;
}

-(void)setupTap{
    self.recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBehind:)];
    [self.recognizer setNumberOfTapsRequired:1];
    if(self.searchResults==0){
            [self.view addGestureRecognizer:self.recognizer];
    }
}

- (void)handleTapBehind:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        if (self.searchResults==0) {
            CGPoint location = [sender locationInView:nil]; //Passing nil gives us coordinates in the window
            
            UIWindow *mainWindow = [[[UIApplication sharedApplication]
                                     delegate] window];
            CGPoint pointInSubview = [self.view convertPoint:location
                                                    fromView:mainWindow];
            if (!CGRectContainsPoint(self.searchBar.bounds, pointInSubview)) {
                // Remove the recognizer first so it's view.window is valid.
                [self.view removeGestureRecognizer:sender];
                [self dismissModalViewControllerAnimated:YES];
            }
        }
    }
}


-(void)setupSubviews{
    self.searchBar = [[FDSearchBar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = HLLocalizedString(@"Search Placeholder");
    self.searchBar.showsCancelButton = YES;
    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.searchBar];
    
    [self.searchBar becomeFirstResponder];
    
    UIView *mainSubView = [self.searchBar.subviews lastObject];
    
    for (id subview in mainSubView.subviews) {
        if ([subview isKindOfClass:[UITextField class]]) {
            UITextField *textField = (UITextField *)subview;
            textField.backgroundColor = [[HLTheme sharedInstance] searchBarInnerBackgroundColor];
        }
    }
    
    self.searchBar.hidden = NO;
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
    self.tableView.translatesAutoresizingMaskIntoConstraints=NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.tableView];
    
    NSDictionary *views = @{ @"top":self.topLayoutGuide,@"searchBar" : self.searchBar,@"trial":self.tableView};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[searchBar]|"
                                                                      options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[trial]|"
                                                                      options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[top][searchBar][trial]|" options:0 metrics:nil views:views]];
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
    FDTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[FDTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    }
    if (indexPath.row < self.searchResults.count) {
        FDArticleContent *article = self.searchResults[indexPath.row];
        [cell.textLabel sizeToFit];
        cell.textLabel.text = article.title;
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row < self.searchResults.count) {
        HLArticleDetailViewController *articlesDetailController = [[HLArticleDetailViewController alloc]init];
        FDArticleContent *article = self.searchResults[indexPath.row];
        articlesDetailController.articleDescription = article.articleDescription;
        articlesDetailController.articleID = article.articleID;
        [self.navigationController setNavigationBarHidden:NO];
        [self.navigationController pushViewController:articlesDetailController animated:YES];
    }
}

-(void)filterArticlesForSearchTerm:(NSString *)term{
    if (term.length > 2){
        term = [FDUtilities replaceSpecialCharacters:term with:@""];
        NSManagedObjectContext *context = [KonotorDataManager sharedInstance].backgroundContext ;
        [context performBlock:^{
            NSArray *articles = [FDRanking rankTheArticleForSearchTerm:term withContext:context];
            if ([articles count] > 0) {
                self.searchResults = articles;
                [self reloadSearchResults];
            }else{
                self.searchResults = nil;
                [self reloadSearchResults];
            }
        }];
    }
    else{
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

-(void)checkNavigationBar{
    [self.navigationController setNavigationBarHidden:YES];
}

-(void)viewWillLayoutSubviews{
    self.searchBar.frame= CGRectMake(0, 0, self.view.frame.size.width, 44);
}


-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    [self dismissModalViewControllerAnimated:YES];
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
        [self.tableView reloadData];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.view endEditing:YES]; 
}



@end