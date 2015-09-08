//
//  FDTicketListViewController.m
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 09/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDTicketListViewController.h"
#import "FDNewTicketViewController.h"
#import "FDCoreDataFetchManager.h"
#import "MobiHelpDatabase.h"
#import "FDAPIClient.h"
#import "FDCoreDataImporter.h"
#import "FDTicket.h"
#import "FDNoteListViewController.h"
#import "FDBadgeView.h"
#import "FDFooterView.h"
#import "FDBarButtonItem.h"
#import "FDKit.h"
#import "FDSecureStore.h"
#import "FDDateUtil.h"
#import "FDConvTableViewCell.h"
#import "FDTicketsUpdater.h"
#import "FDMacros.h"
#import "MobihelpAppState.h"
#import "FDError.h"
#import "FDCoreDataCoordinator.h"

@interface FDTicketListViewController () <UITableViewDelegate,CoreDataFetchManagerDelegate>
@property (strong, nonatomic) FDTableView                *tableView;
@property (strong, nonatomic) NSURLSessionDataTask       *networkQueue;
@property (strong, nonatomic) FDCoreDataFetchManager     *coreDataFetchManager;
@property (strong, nonatomic) NSFetchedResultsController *fetchResultsController;
@property (strong, nonatomic) NSIndexPath                *lastSelectedIP;
@property (strong, nonatomic) FDTheme                    *theme;
@property (strong, nonatomic) FDSecureStore              *secureStore;
@property (strong, nonatomic) FDFooterView               *footerView;
@property (strong, nonatomic) UILabel                    *noTicketsLabel;
@property (strong, nonatomic) MobiHelpDatabase           *database;

@end

#define TICKET_CELL_REUSE_IDENTIFIER @"TicketCell"

@implementation FDTicketListViewController

#pragma mark - Lazy Instantiation

-(FDTableView *)tableView{
    if(!_tableView){
        _tableView = [[FDTableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        [_tableView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.view addSubview:_tableView];
        [self setupTableViewConstraints];
    }
    return _tableView;
}

-(FDSecureStore *)secureStore{
    if(!_secureStore){
        _secureStore = [FDSecureStore sharedInstance];
    }
    return _secureStore;
}

-(MobiHelpDatabase *)database{
    if(!_database){
        _database = [[MobiHelpDatabase alloc] initWithContext:[[FDCoreDataCoordinator sharedInstance] mainContext]];
    }
    return _database;
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

-(NSFetchedResultsController *)fetchResultsController{
    if(!_fetchResultsController){
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:MOBIHELP_DB_TICKET_ENTITY];

        request.fetchBatchSize = 20;
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"updatedDate" ascending:NO selector:nil]];
        NSManagedObjectContext *mobihelpContext = self.database.context;
        _fetchResultsController = [[NSFetchedResultsController alloc]
                                   initWithFetchRequest:request
                                   managedObjectContext:mobihelpContext
                                   sectionNameKeyPath:nil cacheName:nil];
    }
    return _fetchResultsController;
}

-(FDTheme *)theme{
    if(!_theme){
        _theme = [FDTheme sharedInstance];
    }
    return _theme;
}

- (void)handleEmptyTicketsScenario {
    BOOL isEmpty = [self.database isTicketEmpty];
    if (isEmpty) {
        self.view.backgroundColor = [self.theme backgroundColorSDK];
        self.noTicketsLabel = [[UILabel alloc] init];
        self.noTicketsLabel.textColor = [self.theme noItemsFoundMessageColor];
        self.noTicketsLabel.numberOfLines = 0;
        self.noTicketsLabel.textAlignment = NSTextAlignmentCenter;
        self.noTicketsLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.noTicketsLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14.0f];
        [self.noTicketsLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        self.noTicketsLabel.text = FDLocalizedString(@"No Tickets Message" );
        [self.tableView setHidden:YES];
        [self.view addSubview:self.noTicketsLabel];
        
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.noTicketsLabel
                                                               attribute:NSLayoutAttributeTop
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.view
                                                               attribute:NSLayoutAttributeTop
                                                              multiplier:1.0
                                                                constant:100.0]];
        
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.noTicketsLabel
                                                               attribute:NSLayoutAttributeLeading
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.view
                                                               attribute:NSLayoutAttributeLeading
                                                              multiplier:1.0
                                                                constant:20.0]];
        
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.noTicketsLabel
                                                               attribute:NSLayoutAttributeHeight
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:nil
                                                               attribute:NSLayoutAttributeNotAnAttribute
                                                              multiplier:1.0
                                                                constant:100.0]];
        
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.noTicketsLabel
                                                               attribute:NSLayoutAttributeTrailing
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.view
                                                               attribute:NSLayoutAttributeTrailing
                                                              multiplier:1.0
                                                                constant:-20.0]];
        FDNewTicketViewController *newTicketViewController = [[FDNewTicketViewController alloc]initWithModalPresentationType:NO];
        newTicketViewController.sourceController = self;
        [self.navigationController pushViewController:newTicketViewController animated:YES];
    }
}

- (void)viewDidLoad{
    [super viewDidLoad];
    [self handleEmptyTicketsScenario];
    [self setNavigationItem];
    [self setDataSource];
    [self addFooterView];
    [self localNotificationSubscription];
}

-(void)localNotificationSubscription{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationEnteredForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

-(void)localNotificationUnSubscription{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


-(void)applicationEnteredForeground:(NSNotification *)notification{
    [self fetchUpdates];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    BOOL isEmpty = [self.database isTicketEmpty];
    if (!isEmpty) {
        [self.tableView setHidden:NO];
        [self.noTicketsLabel removeFromSuperview];
    }
    [_tableView deselectRowAtIndexPath:_lastSelectedIP animated:NO];
    [self fetchUpdates];
}

-(void)addFooterView {
    self.footerView = [[FDFooterView alloc]initWithController:self];
    [self.view addSubview:self.footerView];
}

#pragma mark - Navigation Stack

-(void)setNavigationItem{
    //Setting the title of the navigation controller
    [self.navigationItem setTitle:FDLocalizedString(@"My Conversations Label" )];

    //Right Bar Button
    UIImage *composeButtonImage = [self.theme getThemedImageFromMHBundleWithName:MOBIHELP_IMAGE_NAV_BAR_COMPOSE_BUTTON];

    FDBarButtonItem *createNewTicketButton = [[FDBarButtonItem alloc] initWithImage:composeButtonImage style:UIBarButtonItemStylePlain target:self action:@selector(createNewTicketButtonAction:)];

    FDBarButtonItem *spacer = [[FDBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spacer.width = -12.0f;
    
    self.navigationItem.rightBarButtonItems = @[spacer, createNewTicketButton];

    //Add left bar button item only when this class is the top view controller
    UIViewController *rootViewController = self.navigationController.viewControllers[0];
    if ([rootViewController isKindOfClass:[FDTicketListViewController class]]) {
        FDBarButtonItem *closeButton = [[FDBarButtonItem alloc] initWithTitle:FDLocalizedString(@"Close Button Text" ) style:UIBarButtonItemStylePlain target:self action:@selector(closeButton:)];
        [self.navigationItem setLeftBarButtonItem:closeButton];
    }
}

-(void)createNewTicketButtonAction:(id)sender{
    BOOL isAppValid = [[MobihelpAppState sharedMobihelpAppState] isAppDisabled];
    if (isAppValid) {
        FDNewTicketViewController *newTicketViewController = [[FDNewTicketViewController alloc]initWithModalPresentationType:NO];
        newTicketViewController.sourceController = self;
        [self.navigationController pushViewController:newTicketViewController animated:YES];
    }
}

-(void)closeButton:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - CoreDataFetchManager

-(void)setDataSource{
    [self setUpCoreDataFetch];
}

-(void)setUpCoreDataFetch{
    self.coreDataFetchManager = [[FDCoreDataFetchManager alloc]initWithTableView:self.tableView withRowAnimation:UITableViewRowAnimationNone];
    self.coreDataFetchManager.delegate                  = self;
    self.coreDataFetchManager.fetchedResultsController  = self.fetchResultsController;
}

-(id)fetchManager:(id)manager cellForTableView:(UITableView *)tableView withObject:(id)object {
    NSString *cellIdentifier = TICKET_CELL_REUSE_IDENTIFIER;
    FDTableViewCell *cell    = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) cell = [[FDConvTableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    FDTicket *ticket      = object;
    cell.textLabel.text = ticket.subject;
    cell.detailTextLabel.text = [FDDateUtil itemCreatedDurationSinceDate:ticket.updatedDate];
    cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
    NSInteger unreadCount = [self.database getUnreadNotesCountForTicketID:ticket.ticketID];
    if (unreadCount) {
        FDBadgeView *badgeView = [[FDBadgeView alloc]initWithFrame:CGRectZero andBadgeNumber:unreadCount];
        [badgeView badgeButtonBackgroundColor:[self.theme badgeButtonBackgroundColor]];
        [badgeView badgeButtonTitleColor:[self.theme badgeButtonTitleColor]];
        cell.accessoryView   = badgeView.badgeButton;
    }else{
        cell.accessoryView = nil;
    }
    return cell;
}

-(void)fetchUpdates{
    BOOL isAppValid = [[MobihelpAppState sharedMobihelpAppState] isAppDisabled];
    if (isAppValid){
        [[[FDTicketsUpdater alloc]init] fetchWithCompletion:^(NSError *error) {
            //Logs visible to the user
            if (error) {
                if(error.code == MOBIHELP_NO_TICKET_EXISTS){
                    NSLog(@"FDDataUpdater : No Ticket exists to update tickets");
                }else{
                    NSLog(@"Warning: Tickets could not be fetched because: %@",error);
                }
            }
        }];
    }
}

#pragma mark - Table View Delegates

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    _lastSelectedIP = indexPath;
    FDTicket *ticket = [self.fetchResultsController objectAtIndexPath:indexPath];
    FDNoteListViewController *noteListController = [[FDNoteListViewController alloc]initWithTicketID:ticket.ticketID];
    [self.navigationController pushViewController:noteListController animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44.0f;
}

-(void)dealloc{
    [self localNotificationUnSubscription];
}

@end
