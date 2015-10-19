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

@interface  HLSearchViewController () <UISearchDisplayDelegate,UISearchBarDelegate>
@property (strong, nonatomic) UITableView               *tableView;
@property (strong, nonatomic) UISearchBar               *searchBar;
@property (strong,nonatomic) UIView *trialView;
//@property (strong, nonatomic) UISearchDisplayController *searchController;
//@property (nonatomic        ) UITableViewRowAnimation   rowAnimation;
//@property (strong, nonatomic) HLTheme                   *theme;
//@property (strong, nonatomic) UIView                    *footerView;
//@property (strong, nonatomic) FDSecureStore             *secureStore;
@end

@implementation HLSearchViewController

//#pragma mark - Initializers
//
//-(instancetype)initWithTableView:(UITableView *)tableView withRowAnimation:(UITableViewRowAnimation)animation{
//    self = [super init];
//    if (self) {
//        self.tableView = tableView;
//        self.tableView.dataSource = self;
//        self.rowAnimation = animation;
//    }
//    return self;
//}
//
//-(instancetype)initWithSearchBar:(UISearchBar *)searchBar withContentsController:(id)controller andTableView:(UITableView *)tableView{
//    self = [self initWithTableView:tableView withRowAnimation:UITableViewRowAnimationNone];
//    if (self) {
//        self.searchBar                                = searchBar;
//        self.searchResults = [[NSArray alloc] init];
//        self.searchController                         = [[UISearchDisplayController alloc]initWithSearchBar:self.searchBar contentsController:controller];
//        self.searchController.searchResultsDataSource = self;
//        self.searchController.delegate                = self;
//        self.searchController.searchResultsDelegate   = controller;
//    }
//    return self;
//}
//
//#pragma mark - LazyInstantiations
//
//-(HLTheme *)theme{
//    if(!_theme){
//        _theme = [HLTheme sharedInstance];
//    }
//    return _theme;
//}
//
//-(FDSecureStore *)secureStore{
//    if(!_secureStore){
//        _secureStore = [FDSecureStore sharedInstance];
//    }
//    return _secureStore;
//}
//
//-(UIView *)footerView{
//    UIView *footerView               = [[UIView alloc] init];
//    footerView.userInteractionEnabled = YES;
//    UIColor *talkToUsButtonTintColor = [self.theme talkToUsButtonColor];
//    int footerViewHeight             = self.searchController.searchResultsTableView.rowHeight;
//    footerView.frame                 = CGRectMake(0, 0, self.tableView.bounds.size.width, footerViewHeight+10);
//    
//    FDButton *submitTicketButton = [FDButton buttonWithType:UIButtonTypeCustom];
//    submitTicketButton.userInteractionEnabled = YES;
//    [submitTicketButton addTarget:self action:@selector(createNewTicket:) forControlEvents:UIControlEventTouchUpInside];
//    [submitTicketButton setTitle:HLLocalizedString(@"Talk To Us Button Text" ) forState:UIControlStateNormal];
//    submitTicketButton.titleLabel.font = [self.theme talkToUsButtonFont];
//    [submitTicketButton setTitleColor:talkToUsButtonTintColor forState:UIControlStateNormal];
//    [submitTicketButton setTranslatesAutoresizingMaskIntoConstraints:NO];
//    submitTicketButton.frame = footerView.frame;
//    [footerView addSubview:submitTicketButton];
//    [footerView addConstraint:[NSLayoutConstraint constraintWithItem:submitTicketButton
//                                                           attribute:NSLayoutAttributeTop
//                                                           relatedBy:NSLayoutRelationEqual
//                                                              toItem:footerView
//                                                           attribute:NSLayoutAttributeTop
//                                                          multiplier:1.0
//                                                            constant:10.0]];
//    
//    [footerView addConstraint:[NSLayoutConstraint constraintWithItem:submitTicketButton
//                                                           attribute:NSLayoutAttributeLeading
//                                                           relatedBy:NSLayoutRelationEqual
//                                                              toItem:footerView
//                                                           attribute:NSLayoutAttributeLeading
//                                                          multiplier:1.0
//                                                            constant:20.0]];
//    
//    [footerView addConstraint:[NSLayoutConstraint constraintWithItem:submitTicketButton
//                                                           attribute:NSLayoutAttributeHeight
//                                                           relatedBy:NSLayoutRelationEqual
//                                                              toItem:nil
//                                                           attribute:NSLayoutAttributeNotAnAttribute
//                                                          multiplier:1.0
//                                                            constant:footerViewHeight]];
//    
//    [footerView addConstraint:[NSLayoutConstraint constraintWithItem:submitTicketButton
//                                                           attribute:NSLayoutAttributeTrailing
//                                                           relatedBy:NSLayoutRelationEqual
//                                                              toItem:footerView
//                                                           attribute:NSLayoutAttributeTrailing
//                                                          multiplier:1.0
//                                                            constant:-20.0]];
//    
//    [submitTicketButton setTitleEdgeInsets:UIEdgeInsetsMake(5, 10, 5, 10)];
//    submitTicketButton.backgroundColor = [UIColor clearColor];
//    submitTicketButton.layer.borderWidth = 1.0f;
//    submitTicketButton.layer.cornerRadius = 5.0f;
//    submitTicketButton.layer.borderColor = talkToUsButtonTintColor.CGColor;
//    submitTicketButton.titleLabel.numberOfLines = 1;
//    submitTicketButton.titleLabel.adjustsFontSizeToFitWidth = YES;
//    submitTicketButton.titleLabel.lineBreakMode = NSLineBreakByClipping;
//    submitTicketButton.titleLabel.textAlignment = NSTextAlignmentCenter;
//    return footerView;
//}
//
//-(void)createNewTicket:(id)sender{
//    [KonotorFeedbackScreen showFeedbackScreen];
//}
//
#pragma mark - TableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)sectionIndex{
    return self.searchResults.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
        id object = [self.searchResults objectAtIndex:indexPath.row];
        return [self cellForSearchTableView:tableView withObject:object];
}

-(id)cellForSearchTableView:(UITableView *)tableView withObject:(id)object {
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

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    HLArticleDetailViewController *articlesDetailController = [[HLArticleDetailViewController alloc]init];
    FDArticleContent *article = [self.searchResults objectAtIndex:indexPath.row];
    articlesDetailController.articleDescription = article.articleDescription;
    articlesDetailController.articleID = article.articleID;
    [self.navigationController setNavigationBarHidden:NO];
    [self.navigationController pushViewController:articlesDetailController animated:YES];
}

//
//#pragma mark NSFetchedResultsController Delegate
//
//- (void)controllerWillChangeContent:(NSFetchedResultsController*)controller{
//    [self.tableView beginUpdates];
//}
//
//- (void)controllerDidChangeContent:(NSFetchedResultsController*)controller{
//    [self.tableView endUpdates];
//}
//
//- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
//       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
//    UITableViewRowAnimation preferredAnimation = self.rowAnimation;
//    switch(type){
//        case NSFetchedResultsChangeInsert:
//            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:preferredAnimation];
//            break;
//        case NSFetchedResultsChangeDelete:
//            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:preferredAnimation];
//            break;
//        case NSFetchedResultsChangeUpdate:
//            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
//            break;
//        case NSFetchedResultsChangeMove:
//            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:preferredAnimation];
//            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:preferredAnimation];
//            break;
//    }
//}
//
//- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
//           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
//    switch(type) {
//        case NSFetchedResultsChangeInsert:
//            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeDelete:
//            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeMove:
//            //Implement when needed later
//            break;
//            
//        case NSFetchedResultsChangeUpdate:
//            FDLog(@"Am i being called ever ???");
//            break;
//            
//    }
//}
//
//#pragma mark - UISearch Display Controller
//
//-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString{
//    [self filterArticlesForSearchTerm:trimString(searchString)];
//    [self hideEmptyListIndicatorLabel];
//    return NO;
//}
//
////Hack to remove "No Results" label from search display controller
//-(void)hideEmptyListIndicatorLabel{
//    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.001);
//    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//        for (UIView* subview in self.searchController.searchResultsTableView.subviews) {
//            if ([subview isKindOfClass: [UILabel class]] &&
//                [[(UILabel*)subview text] isEqualToString:@"No Results"]) {
//                UILabel *targetView = (UILabel *)subview;
//                [targetView setText:@""];
//                break;
//            }
//        }
//    });
//}
//
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
//
-(void)fetchAllArticles{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_ARTICLE_ENTITY];
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].mainObjectContext;
    [context performBlock:^{
        self.searchResults = [context executeFetchRequest:request error:nil];
        [self reloadSearchResults];
    }];
}
//
-(void)reloadSearchResults{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}
//
//-(void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller{
//    self.searchBar.hidden = YES;
//}
//
//

-(void)viewWillAppear:(BOOL)animated{
    [self checkNavigationBar];
    self.view.userInteractionEnabled=YES;
}

-(void)viewDidLoad{
    [super viewDidLoad];
    [self setupSearchBar];
//    self.view.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
}

-(void)checkNavigationBar{
    [self.navigationController setNavigationBarHidden:YES];
}

-(void)setupSearchBar{
    self.searchBar = [[FDSearchBar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = HLLocalizedString(@"Search Placeholder");
    self.searchBar.showsCancelButton=YES;
    self.searchBar.translatesAutoresizingMaskIntoConstraints=NO;
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

-(void)viewWillLayoutSubviews{
    self.searchBar.frame= CGRectMake(0, 0, self.view.frame.size.width, 44);
}


-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    [self dismissModalViewControllerAnimated:NO];
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    NSInteger searchStringLength = searchText.length;
    if (searchStringLength!=0) {
        self.tableView.alpha = 1.0;
        [self filterArticlesForSearchTerm:searchText];
    }else{
        self.searchResults = nil;
        [self.tableView reloadData];
    }
}

@end