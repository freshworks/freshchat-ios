//
//  FDArticleListViewController.m
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 06/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDAPIClient.h"
#import "MobiHelpDatabase.h"
#import "FDFolder.h"
#import "FDArticle.h"
#import "FDCoreDataFetchManager.h"
#import "FDArticleListViewController.h"
#import "FDArticleDetailViewController.h"
#import "FDFolderListViewController.h"
#import "FDFooterView.h"
#import "FDKit.h"
#import "FDSecureStore.h"
#import "FDMacros.h"
#import "FDCoreDataCoordinator.h"
#import "FDTag.h"

@interface FDArticleListViewController () <CoreDataFetchManagerDelegate, UITableViewDelegate>

@property (strong, nonatomic) FDTableView                *tableView;
@property (strong, nonatomic) FDCoreDataFetchManager     *coreDataFetchManager;
@property (strong, nonatomic) NSFetchedResultsController *fetchResultsController;
@property (strong, nonatomic) FDFooterView               *footerView;
@property (strong, nonatomic) FDTheme                    *theme;
@property (strong, nonatomic) NSIndexPath                *lastSelectedIP;
@property (strong, nonatomic) FDSecureStore              *secureStore;
@property (nonatomic) BOOL isModalView;
@property (strong, nonatomic) NSMutableDictionary        *titlesDictionary;

@end

#define ARTICLE_CELL_REUSE_IDENTIFIER @"ArticleCell"

@implementation FDArticleListViewController

#pragma mark - Lazy Instantiations

-(FDSecureStore *)secureStore{
    if(!_secureStore){
        _secureStore = [FDSecureStore sharedInstance];
    }
    return _secureStore;
}

-(instancetype)initWithModalPresentationType:(BOOL)isModalPresentation {
    self = [super init];
    if (self) {
        self.isModalView = isModalPresentation;
    }
    return self;
}

-(UITableView *)tableView{
    if(!_tableView){
        _tableView = [[FDTableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        [self.view addSubview:_tableView];
        [_tableView setTranslatesAutoresizingMaskIntoConstraints:NO];
        self.titlesDictionary = [[NSMutableDictionary alloc] init];
        [self setupTableViewConstraints];

        if (self.tagsArray) {
            _tableView.tableFooterView = [self getFooterView];
        }else{
            _tableView.tableFooterView = [[UIView alloc]init];
        }
        
    }
    return _tableView;
}

-(void)setTagsArray:(NSArray *)tagsArray{
    NSMutableArray *mutableTagsArray = [tagsArray mutableCopy];
    [mutableTagsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        mutableTagsArray[idx] = [obj lowercaseString];
    }];
    _tagsArray = mutableTagsArray;
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
    }
    
    else {
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

-(FDTheme *)theme{
    if(!_theme){
        _theme = [FDTheme sharedInstance];
    }
    return _theme;
}


#pragma mark - ViewController Initialization
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [_tableView deselectRowAtIndexPath:_lastSelectedIP animated:NO];
}

-(void)addFooterView {
    self.footerView = [[FDFooterView alloc]initWithController:self];
    [self.view addSubview:self.footerView];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    [self setNavigationItem];
    [self setDataSource];
    [self addFooterView];
}

-(UIView *)getFooterView{
    int footerViewHeight = 44;
    UIView *footerView = [[UIView alloc] init];
    footerView.frame  = CGRectMake(0, 0, self.tableView.bounds.size.width, footerViewHeight+10);
    footerView.userInteractionEnabled = YES;
    UIColor *buttonTintColor = [self.theme talkToUsButtonColor];
    FDButton *button = [FDButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:FDLocalizedString(@"Show All Solutions Button Text" ) forState:UIControlStateNormal];
    button.backgroundColor = [UIColor clearColor];
    button.translatesAutoresizingMaskIntoConstraints= NO;
    button.userInteractionEnabled = YES;
    [button addTarget:self action:@selector(showAllSolutions:) forControlEvents:UIControlEventTouchUpInside];
    button.titleLabel.font = [UIFont fontWithName:[self.theme talkToUsButtonFontName] size:[self.theme talkToUsButtonFontSize]];
    [button setTitleColor:buttonTintColor forState:UIControlStateNormal];
    [button setTitleEdgeInsets:UIEdgeInsetsMake(5, 10, 5, 10)];
    button.layer.borderWidth = 1.0f;
    button.layer.cornerRadius = 5.0f;
    button.layer.borderColor = buttonTintColor.CGColor;
    button.titleLabel.numberOfLines = 1;
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleLabel.lineBreakMode = NSLineBreakByClipping;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    [footerView addSubview:button];

    NSDictionary *views = @{ @"button" : button };
    [footerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(<=10)-[button]-(<=10)-|"
                                                                       options:0 metrics:nil views:views]];
    [footerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[button(44)]|"
                                                                       options:0 metrics:nil views:views]];
    return footerView;
}

-(void)showAllSolutions:(id)sender{
    [self.secureStore setBoolValue:YES forKey:MOBIHELP_DEFAULTS_IS_CONVERSATIONS_DISABLED];
    FDFolderListViewController *folderListViewController = [[FDFolderListViewController alloc]init];
    UINavigationController *navigationController = [[UINavigationController alloc]initWithNavigationBarClass:[FDNavigationBar class] toolbarClass:nil];
    [navigationController setViewControllers:[NSArray arrayWithObject:folderListViewController]];
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - Navigation Stack

-(void)setNavigationItem{
    [self.navigationItem setTitle:FDLocalizedString(@"Solutions Nav Bar Title Text")];
    if(self.isModalView)
    {
        FDBarButtonItem *backButton = [[FDBarButtonItem alloc]initWithTitle:FDLocalizedString(@"Solutions Nav Bar Back Button Text") style:UIBarButtonItemStylePlain target:self action:@selector(closeButton:)];
        [self.navigationItem setLeftBarButtonItem:backButton];
    }
}

-(void)closeButton:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - CoreDataFetchManager

-(void)setDataSource{
    [self setUpCoreDataFetch];
}

-(NSFetchedResultsController *)fetchResultsController{
    NSManagedObjectContext *mobihelpContext = [[FDCoreDataCoordinator sharedInstance] mainContext];
    if(!_fetchResultsController){
        if (self.tagsArray) {
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:MOBIHELP_DB_TAG_ENTITY];
            request.predicate = [NSPredicate predicateWithFormat:@"tagName IN %@",self.tagsArray];
            NSArray* results = [mobihelpContext executeFetchRequest:request error:nil];
            NSMutableArray *articleIDs = [[NSMutableArray alloc] init];
            for (FDTag* tag in results) {
                [articleIDs addObject:tag.itemID];
            }
            request = [NSFetchRequest fetchRequestWithEntityName:MOBIHELP_DB_ARTICLE_ENTITY];
            request.fetchBatchSize = 20;
            request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"articleID" ascending:YES selector:nil]];
            request.predicate = [NSPredicate predicateWithFormat:@"articleID IN %@",articleIDs];
            _fetchResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:mobihelpContext sectionNameKeyPath:nil cacheName:nil];
        }else{
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:MOBIHELP_DB_ARTICLE_ENTITY];
            request.fetchBatchSize = 20;
            request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"position" ascending:YES selector:nil]];
            request.predicate = [NSPredicate predicateWithFormat:@"folder.folderID == %@",self.articleFolder.folderID];
            _fetchResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:mobihelpContext sectionNameKeyPath:nil cacheName:nil];
        }
    }
    return _fetchResultsController;
}


-(void)setUpCoreDataFetch{
    self.coreDataFetchManager = [[FDCoreDataFetchManager alloc]initWithTableView:self.tableView withRowAnimation:UITableViewRowAnimationBottom];
    self.coreDataFetchManager.fetchedResultsController = self.fetchResultsController;
    self.coreDataFetchManager.delegate                 = self;
}

-(id)fetchManager:(id)manager cellForTableView:(UITableView *)tableView withObject:(id)object {
    NSString *cellIdentifier = ARTICLE_CELL_REUSE_IDENTIFIER;
    FDTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[FDTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    FDArticle *article = (FDArticle *)object;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [cell.textLabel sizeToFit];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = article.title;
    cell.backgroundColor = [self.theme tableViewCellBackgroundColor];
    return cell;
}

#pragma mark - TableViewDelegates

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    _lastSelectedIP = indexPath;
    FDArticleDetailViewController *articlesDetailController = [[FDArticleDetailViewController alloc]init];
    FDArticle *article = [self.fetchResultsController objectAtIndexPath:indexPath];
    articlesDetailController.articleDescription = article.articleDescription;
    [self.navigationController pushViewController:articlesDetailController animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellText;
    FDArticle *article = [self.fetchResultsController objectAtIndexPath:indexPath];
    cellText = article.title;
    
    UIFont *cellFont = [UIFont fontWithName:[self.theme tableViewCellFontName] size:[self.theme tableViewCellFontSize]];

    CGSize labelSize = CGSizeZero;
    
    if (cellText) {
        NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:cellText attributes:@{NSFontAttributeName:cellFont}];
        CGRect rect = [attributedText boundingRectWithSize:(CGSize){[UIScreen mainScreen].bounds.size.width - 40, CGFLOAT_MAX} options:NSStringDrawingUsesLineFragmentOrigin context:nil];
        labelSize = rect.size;
    }
    
    return labelSize.height + 30;
}

@end