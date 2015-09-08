//
//  FDCoreDataFetchManager.m
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 29/04/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDCoreDataFetchManager.h"
#import "MobiHelpDatabase.h"
#import "FDNewTicketViewController.h"
#import "FDKit.h"
#import "FDUtilities.h"
#import "FDSecureStore.h"
#import "FDMacros.h"
#import "MobihelpAppState.h"
#import "FDFolderListViewController.h"
#include "FDRanking.h"
#import "FDCoreDataCoordinator.h"

@interface  FDCoreDataFetchManager () <UISearchDisplayDelegate>
@property (strong, nonatomic) UITableView               *tableView;
@property (strong, nonatomic) UISearchBar               *searchBar;
@property (strong, nonatomic) UISearchDisplayController *searchController;
@property (nonatomic        ) UITableViewRowAnimation   rowAnimation;
@property (strong, nonatomic) FDTheme                   *theme;
@property (strong, nonatomic) UIView                    *footerView;
@property (strong, nonatomic) FDSecureStore             *secureStore;
@end

@implementation FDCoreDataFetchManager

#pragma mark - Initializers

-(instancetype)initWithTableView:(UITableView *)tableView withRowAnimation:(UITableViewRowAnimation)animation{
    self = [super init];
    if (self) {
        self.tableView = tableView;
        self.tableView.dataSource = self;
        self.rowAnimation = animation;
    }
    return self;
}

-(instancetype)initWithSearchBar:(UISearchBar *)searchBar withContentsController:(id)controller andTableView:(UITableView *)tableView{
    self = [self initWithTableView:tableView withRowAnimation:UITableViewRowAnimationNone];
    if (self) {
        self.searchBar                                = searchBar;
        self.searchController                         = [[UISearchDisplayController alloc]initWithSearchBar:self.searchBar contentsController:controller];
        self.searchController.searchResultsDataSource = self;
        self.searchController.delegate                = self;
        self.searchController.searchResultsDelegate   = controller;
    }
    return self;
}


#pragma mark - LazyInstantiations

- (void)setFetchedResultsController:(NSFetchedResultsController*)fetchedResultsController{
    if(!_fetchedResultsController){
        _fetchedResultsController = fetchedResultsController;
        _fetchedResultsController.delegate = self;
        [self performFetch];
    }
}

-(void)performFetch{
    [self.fetchedResultsController performFetch:NULL];
}

-(FDTheme *)theme{
    if(!_theme){
        _theme = [FDTheme sharedInstance];
    }
    return _theme;
}

-(FDSecureStore *)secureStore{
    if(!_secureStore){
        _secureStore = [FDSecureStore sharedInstance];
    }
    return _secureStore;
}

-(UIView *)footerView{
    UIView *footerView               = [[UIView alloc] init];
    footerView.userInteractionEnabled = YES;
    UIColor *talkToUsButtonTintColor = [self.theme talkToUsButtonColor];
    int footerViewHeight             = self.searchController.searchResultsTableView.rowHeight;
    footerView.frame                 = CGRectMake(0, 0, self.tableView.bounds.size.width, footerViewHeight+10);
    
    FDButton *submitTicketButton = [FDButton buttonWithType:UIButtonTypeCustom];
    submitTicketButton.userInteractionEnabled = YES;
    [submitTicketButton addTarget:self action:@selector(createNewTicket:) forControlEvents:UIControlEventTouchUpInside];
    [submitTicketButton setTitle:FDLocalizedString(@"Talk To Us Button Text" ) forState:UIControlStateNormal];
    submitTicketButton.titleLabel.font = [UIFont fontWithName:[self.theme talkToUsButtonFontName] size:[self.theme talkToUsButtonFontSize]];
    [submitTicketButton setTitleColor:talkToUsButtonTintColor forState:UIControlStateNormal];
    [submitTicketButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    submitTicketButton.frame = footerView.frame;
    [footerView addSubview:submitTicketButton];
    [footerView addConstraint:[NSLayoutConstraint constraintWithItem:submitTicketButton
                                                           attribute:NSLayoutAttributeTop
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:footerView
                                                           attribute:NSLayoutAttributeTop
                                                          multiplier:1.0
                                                            constant:10.0]];
    
    [footerView addConstraint:[NSLayoutConstraint constraintWithItem:submitTicketButton
                                                           attribute:NSLayoutAttributeLeading
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:footerView
                                                           attribute:NSLayoutAttributeLeading
                                                          multiplier:1.0
                                                            constant:20.0]];
    
    [footerView addConstraint:[NSLayoutConstraint constraintWithItem:submitTicketButton
                                                           attribute:NSLayoutAttributeHeight
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:nil
                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                          multiplier:1.0
                                                            constant:footerViewHeight]];
    
    [footerView addConstraint:[NSLayoutConstraint constraintWithItem:submitTicketButton
                                                           attribute:NSLayoutAttributeTrailing
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:footerView
                                                           attribute:NSLayoutAttributeTrailing
                                                          multiplier:1.0
                                                            constant:-20.0]];
    
    [submitTicketButton setTitleEdgeInsets:UIEdgeInsetsMake(5, 10, 5, 10)];
    submitTicketButton.backgroundColor = [UIColor clearColor];
    submitTicketButton.layer.borderWidth = 1.0f;
    submitTicketButton.layer.cornerRadius = 5.0f;
    submitTicketButton.layer.borderColor = talkToUsButtonTintColor.CGColor;
    submitTicketButton.titleLabel.numberOfLines = 1;
    submitTicketButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    submitTicketButton.titleLabel.lineBreakMode = NSLineBreakByClipping;
    submitTicketButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    return footerView;
}

-(void)createNewTicket:(id)sender{
    FDNewTicketViewController *newTicketViewController = [[FDNewTicketViewController alloc]initWithModalPresentationType:NO];
    newTicketViewController.ticketDescription = trimString(self.searchBar.text);
    UIViewController *contentsController = self.searchController.searchContentsController;
    newTicketViewController.sourceController = contentsController;
    [self.searchBar resignFirstResponder];
    [contentsController.navigationController pushViewController:newTicketViewController animated:YES];
}

- (void)setPaused:(BOOL)paused{
    _paused = paused;
    if (paused) {
        self.fetchedResultsController.delegate = nil;
    } else {
        self.fetchedResultsController.delegate = self;
        [self.fetchedResultsController performFetch:NULL];
        [self.tableView reloadData];
    }
}

#pragma mark - TableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView{
    if (tableView == self.tableView) {
        return self.fetchedResultsController.sections.count;
    }else{
        return 1;
    }
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)sectionIndex{
    if (tableView == self.tableView) {
        id<NSFetchedResultsSectionInfo> section = self.fetchedResultsController.sections[sectionIndex];
        return section.numberOfObjects;
    }else if(tableView == self.searchController.searchResultsTableView){
        return self.searchResults.count;
    }
    return 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == self.tableView) {
        id object = [self.fetchedResultsController objectAtIndexPath:indexPath];
        return [self.delegate fetchManager:self cellForTableView:tableView withObject:object];
    }else{
        id object = [self.searchResults objectAtIndex:indexPath.row];
        return [self.delegate fetchManager:self cellForSearchTableView:tableView withObject:object];
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    id fetchManagerDelegate = self.delegate;
    NSString *sectionName = nil;
    if ([fetchManagerDelegate isKindOfClass:[FDFolderListViewController class]]) {
        return (tableView == self.tableView) ? [self getSectionNameForSection:section] : nil;
    }else{
        return nil;         
    }
    return sectionName;
}

-(NSString *)getSectionNameForSection:(NSInteger)section{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    NSNumber *categoryPos = [formatter numberFromString:[[[self.fetchedResultsController sections] objectAtIndex:section] name]];
    NSFetchRequest *request         = [[NSFetchRequest alloc]initWithEntityName:MOBIHELP_DB_FOLDER_ENTITY];
    NSPredicate *searchFilter       = [NSPredicate predicateWithFormat:@"categoryPosition == %@",categoryPos];
    request.predicate               = searchFilter;
    NSManagedObjectContext *context = [[FDCoreDataCoordinator sharedInstance] mainContext];
    NSArray *matches                = [context executeFetchRequest:request error:nil];
    FDFolder *folder                = [matches firstObject];
    return folder.categoryName;
}

#pragma mark NSFetchedResultsController Delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController*)controller{
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController*)controller{
    [self.tableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    UITableViewRowAnimation preferredAnimation = self.rowAnimation;
    switch(type){
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:preferredAnimation];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:preferredAnimation];
            break;
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:preferredAnimation];
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:preferredAnimation];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeMove:
            //Implement when needed later
        break;
            
        case NSFetchedResultsChangeUpdate:
            FDLog(@"Am i being called ever ???");
        break;
            
    }
}

#pragma mark - UISearch Display Controller

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString{
    [self filterArticlesForSearchTerm:trimString(searchString)];
    [self hideEmptyListIndicatorLabel];
    return NO;
}

//Hack to remove "No Results" label from search display controller
-(void)hideEmptyListIndicatorLabel{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.001);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        for (UIView* subview in self.searchController.searchResultsTableView.subviews) {
            if ([subview isKindOfClass: [UILabel class]] &&
                [[(UILabel*)subview text] isEqualToString:@"No Results"]) {
                UILabel *targetView = (UILabel *)subview;
                [targetView setText:@""];
                break;
            }
        }
    });
}

-(void)filterArticlesForSearchTerm:(NSString *)term{
    if (term.length > 2){
        term = [FDUtilities replaceSpecialCharacters:term with:@""];
        NSManagedObjectContext *context = [[FDCoreDataCoordinator sharedInstance] getBackgroundContext];
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
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:MOBIHELP_DB_ARTICLE_ENTITY];
    NSManagedObjectContext *context = [[FDCoreDataCoordinator sharedInstance]mainContext];
    [context performBlock:^{
        self.searchResults = [context executeFetchRequest:request error:nil];
        [self reloadSearchResults];
    }];
}

-(void)reloadSearchResults{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.searchController.searchResultsTableView reloadData];
    });
}

-(void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView{
    BOOL isAppValid = [[MobihelpAppState sharedMobihelpAppState] isAppDisabled];
    UIView *footerView = [[UIView alloc]init];
    if (isAppValid) {
        if (![self.secureStore boolValueForKey:MOBIHELP_DEFAULTS_IS_CONVERSATIONS_DISABLED]) {
            footerView = self.footerView;
        }
    }
    controller.searchResultsTableView.tableFooterView = footerView;
}

-(void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller{
    self.searchBar.hidden = YES;
}

@end