//
//  FDNoteListViewController.m
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 28/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDNoteListViewController.h"
#import "FDArticleDetailViewController.h"
#import "MobiHelpDatabase.h"
#import "FDCoreDataImporter.h"
#import "FDProgressHUD.h"
#import "FDNote.h"
#import "FDDateUtil.h"
#import "FDSecureStore.h"
#import "FDReachability.h"
#import "FDNoteContent.h"
#import "FDUtilities.h"
#import "FDConstants.h"
#import "FDError.h"
#import "MobihelpAppState.h"
#import "FDTicketStateHandler.h"
#import "FDNewTicketViewController.h"
#import "FDTicketListViewController.h"
#import "FDInputToolbarView.h"
#import "FDClosedPromptView.h"
#import "FDResolvedPromptView.h"
#import "FDCoreDataCoordinator.h"

@interface FDNoteListViewController ()

@property (strong, nonatomic) FDCoreDataFetchManager     *coreDataFetchManager;
@property (strong, nonatomic) NSFetchedResultsController *fetchResultsController;
@property (strong, nonatomic) FDTheme                    *theme;
@property (strong, nonatomic) FDSecureStore              *secureStore;
@property (strong, nonatomic) FDReachability             *reachability;
@property (strong, nonatomic) UIView                     *closedResolvedPrompt;
@property (strong, nonatomic) FDTicketStateHandler       *ticketStateDisplayer;
@property (strong, nonatomic) NSTimer                    *pollingTimer;
@property (strong, nonatomic) NSNumber                   *ticketID;
@property (nonatomic)         CGFloat                    keyBoardHeight;
@property (nonatomic, strong) FDInputToolbarView         *inputToolbar;
@property (strong, nonatomic) UIView                     *bottomView;
@property (strong, nonatomic) NSLayoutConstraint         *bottomViewHeightConstraint;
@property (strong, nonatomic) NSLayoutConstraint         *bottomViewBottomConstraint;
@property (strong, nonatomic) MobiHelpDatabase           *database;

@end

#define NOTE_CELL_REUSE_IDENTIFIER     @"NoteCell"
#define MESSAGE_RATING_CELL_IDENTIFIER @"MessageCellIdentifier"

static CGFloat TOOLBAR_HEIGHT      = 40;
static CGFloat PROMPT_VIEW_HEIGHT  = 100;

@implementation FDNoteListViewController

@synthesize tableView, keyBoardHeight, bottomViewHeightConstraint ,bottomViewBottomConstraint ;

#pragma mark - Lazy Instantiations

-(MobiHelpDatabase *)database{
    if(!_database){
        _database = [[MobiHelpDatabase alloc] initWithContext:[[FDCoreDataCoordinator sharedInstance] mainContext]];
    }
    return _database;
}

-(NSFetchedResultsController *)fetchResultsController{
    if(!_fetchResultsController){
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:MOBIHELP_DB_NOTE_ENTITY];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdDate" ascending:YES selector:nil]];
        request.predicate = [NSPredicate predicateWithFormat:@"ticket.ticketID == %@",self.ticketID];
        _fetchResultsController = [[NSFetchedResultsController alloc]
                                   initWithFetchRequest:request managedObjectContext:self.database.context sectionNameKeyPath:nil cacheName:nil];
    }
    return _fetchResultsController;
}

#pragma mark - Designated Initializer

-(instancetype)initWithTicketID:(NSNumber *)ticketID{
    self = [super init];
    if (self) {
        self.ticketID = ticketID;
        self.theme = [FDTheme sharedInstance];
        self.secureStore = [FDSecureStore sharedInstance];
        self.ticketStateDisplayer = [[FDTicketStateHandler alloc]initWithDelegate:self];
    }
    return self;
}

#pragma mark - View Controller Initializations

- (void)viewDidLoad{
    [super viewDidLoad];
    [self setSubviews];
    [self setDataSource];
    [self setBackgroundColor];
    [self setNavBarTitle];
    [self updateUnreadNotes];
    [self fetchUpdates];
    [self localNotificationSubscription];
    [self checkNetworkReachability];
    [self handleTicketState];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self startPoller];
    [self scrollTableViewToLastCell];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self cancelPoller];
    HideNetworkActivityIndicator();
}

-(UIView *)headerView{
    float headerViewWidth      = self.view.frame.size.width;
    float headerViewHeight     = 25;
    CGRect headerViewFrame     = CGRectMake(0, 0, headerViewWidth, headerViewHeight);
    UIView *headerView = [[UIView alloc]initWithFrame:headerViewFrame];
    headerView.backgroundColor = [self.theme backgroundColorSDK];
    return headerView;
}

-(void)setSubviews{

    //Tableview
    tableView                     = [[FDTableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.delegate            = self;
    tableView.separatorStyle      = UITableViewCellSeparatorStyleNone;
    tableView.tableHeaderView = [self headerView];
    [tableView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:tableView];
    
    //Bottomview
    self.bottomView = [[UIView alloc]init];
    self.bottomView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.bottomView];
    
    bottomViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.bottomView
                                                              attribute:NSLayoutAttributeHeight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:nil
                                                              attribute:NSLayoutAttributeNotAnAttribute
                                                             multiplier:1.0
                                                               constant:TOOLBAR_HEIGHT];
    
    bottomViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.bottomView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0 constant:0];
    
    
    self.inputToolbar = [[FDInputToolbarView alloc]initWithDelegate:self];
    self.inputToolbar.translatesAutoresizingMaskIntoConstraints = NO;
    BOOL isEnhancedPrivacyEnabled = [[FDSecureStore sharedInstance] boolValueForKey:MOBIHELP_DEFAULTS_IS_ENHANCED_PRIVACY_ENABLED];
    [self.inputToolbar showAttachButton:!isEnhancedPrivacyEnabled];


    //Initial Constraints
    NSDictionary *views = @{@"tableView" : self.tableView, @"bottomView" : self.bottomView};
    [self.view addConstraint:bottomViewBottomConstraint];
    [self.view addConstraint:bottomViewHeightConstraint];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bottomView]|" options:0 metrics:nil views:views]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView][bottomView]" options:0 metrics:nil views:views]];

    [self updateBottomViewWith:self.inputToolbar andHeight:TOOLBAR_HEIGHT];
}


-(void)updateBottomViewWith:(UIView *)view andHeight:(CGFloat) height{
    [[self.bottomView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

    [self.bottomView addSubview:view];
    bottomViewHeightConstraint.constant = height;

    NSDictionary *views = @{ @"bottomInputView" : view };
    [self.bottomView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bottomInputView]|" options:0 metrics:nil views:views]];
    [self.bottomView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[bottomInputView]|" options:0 metrics:nil views:views]];
}

-(void)checkNetworkReachability{
    self.reachability = [FDReachability reachabilityWithHostname:@"www.google.com"];
    __weak typeof(self)weakSelf = self;

    //Internet is reachable
    self.reachability.reachableBlock = ^(FDReachability*reach){
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.inputToolbar enableSendButton:YES];
        });
    };

    //Internet Unreachable
    self.reachability.unreachableBlock = ^(FDReachability*reach){
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.inputToolbar enableSendButton:NO];
        });
    };
    
    [self.reachability startNotifier];
}

-(void)handleTicketState{
    FDTicket *ticket = [FDTicket getTicketWithID:self.ticketID inManagedObjectContext:self.database.context];
    [self.ticketStateDisplayer handleTicketState:[ticket.status integerValue]];
}

-(void)dismissKeyboard{
    [self.view endEditing:YES];
}

-(void)startPoller{
    if(![self.pollingTimer isValid]){
        self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:NOTE_LIST_POLLING_INTERVAL target:self selector:@selector(pollNewNotes:) userInfo:nil repeats:YES];
        FDLog(@"Starting Poller");
    }
}

-(void)cancelPoller{
    if([self.pollingTimer isValid]){
        [self.pollingTimer invalidate];
        FDLog(@"Cancelled Poller");
    }
}

-(void)handleBecameActive:(NSNotification *)notification{
    [self startPoller];
}

-(void)handleEnteredBackground:(NSNotification *)notification{
    [self cancelPoller];
}

#pragma mark -

-(void)setBackgroundColor{
    self.view.backgroundColor = [self.theme backgroundColorSDK];
}

-(void)setNavBarTitle{
    self.title = FDLocalizedString(@"Conversation Nav Bar Title Text" );
}

-(void)updateUnreadNotes{
    NSArray *unreadNotes = [self.database getUnreadNotesForTicketID:self.ticketID];
    for (FDNote *note in unreadNotes) {
        note.unread = @NO;
    }
    [self.database saveContextWithDebugMessage:@"All unread notes were read"];
}

- (void)handleDataModelChanges:(NSNotification *)note{
    NSSet *insertedObjects = [[note userInfo] objectForKey:NSInsertedObjectsKey];
    if ([insertedObjects count]) {
        [self scrollTableViewToLastCell];
    }
}

-(void)localNotificationSubscription{
    NSManagedObjectContext *contextToWatch = self.database.context;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelChanges:) name:NSManagedObjectContextObjectsDidChangeNotification object:contextToWatch];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnteredBackground:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleBecameActive:)
                                                 name: UIApplicationDidBecomeActiveNotification
                                               object: nil];
}

-(void)localNotificationUnSubscription{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Table View Delegates

-(id)fetchManager:(id)manager cellForTableView:(UITableView *)otherTableView withObject:(id)object {
    NSString *cellIdentifier = NOTE_CELL_REUSE_IDENTIFIER;
    FDMessagingCell *cell    = [otherTableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[FDMessagingCell alloc]initMessagingCellWithReuseIdentifier:cellIdentifier];
        cell.messageLabelFont  = [UIFont fontWithName:[self.theme chatBubbleFontName] size:[self.theme chatBubbleFontSize]];
    }
    FDNote *note = object;
    
    if ([note.source isEqualToNumber:@11]) {
        return [self getReviewRequestCellForCell];
    }else{
        return [self getCellWithNote:note forCell:cell];
    }
    return cell;
}

-(id)getReviewRequestCellForCell {
    FDMessagingCell *reviewRequestCell = [[FDMessagingCell alloc] initRatingCellWithReuseIdentifier:MESSAGE_RATING_CELL_IDENTIFIER];
    reviewRequestCell.selectionStyle = UITableViewCellSelectionStyleNone;
    reviewRequestCell.source = @11;
    return reviewRequestCell;
}

-(id)getCellWithNote:(FDNote *)note forCell:(id)cell{
    BOOL isSentMessage           = [note.incoming boolValue];
    FDMessagingCell *noteCell    = cell;
    noteCell.delegate            = self;
    noteCell.sent                = isSentMessage;
    noteCell.timeLabel.text      = [FDDateUtil itemCreatedDurationSinceDate:note.createdDate];
    noteCell.timeLabel.textColor = [self.theme noteUpdateTimeStatusColor];
    noteCell.backgroundColor     = [self.theme backgroundColorSDK];

    if (note.hasAttachment) {
        noteCell.imagePreview.image = [UIImage imageWithData:note.attachmentOriginal];
    }else{
        noteCell.imagePreview.image = nil;
    }

    if (isSentMessage) {
        noteCell.sentMessageLabel.text   = note.body;
    }else{
        noteCell.receivedMessageLabel.text   = note.body;
    }

    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    FDNote *note = [self.fetchResultsController objectAtIndexPath:indexPath];
    FDMessagingCell *cell = [self fetchManager:nil cellForTableView:self.tableView withObject:note];
    
    CGSize messageSize = [FDMessagingCell messageSize:note.body forFont:cell.messageLabelFont];
    CGSize imageSize = [FDMessagingCell imageSize:cell.imagePreview.image.size forTextSize:messageSize];
    
    if ([note.source isEqualToNumber:@11]) {
        UIFont *reviewLabelFont = [UIFont fontWithName:[self.theme rateOnAppStoreLabelFontName] size:[self.theme rateOnAppStoreLabelFontSize]];
        CGSize ratingMessageSize = [FDMessagingCell rateOnAppStoreLabelSize:FDLocalizedString(@"Review Label Text") forFont:reviewLabelFont];
        return ratingMessageSize.height + 100.0f;
    }
    
    else {
        if (note.hasAttachment) {
            return messageSize.height + imageSize.height + 2*[FDMessagingCell textMarginVertical] + 25.0f;
        }
        
        else {
            return messageSize.height + 2*[FDMessagingCell textMarginVertical] + 25.0f;
        }
    }
}

-(void)scrollTableViewToLastCell{
    NSInteger lastCellIndex = [[self.fetchResultsController fetchedObjects]count]-1;
    if (lastCellIndex >0 ) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:lastCellIndex inSection:0];
        NSUInteger noOfRows = [self.tableView numberOfRowsInSection:indexPath.section];
        if (noOfRows==0) {
            [self.tableView reloadData];
            FDLog(@"Table Reloaded");
        }
        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

#pragma mark - WebService

-(void)pollNewNotes:(NSTimer *)timer{
    [self fetchUpdates];
}

-(void)fetchUpdates{
    BOOL isAppValid = [[MobihelpAppState sharedMobihelpAppState] isAppDisabled];
    if (isAppValid) {
        [self importFreshData];
    }
}

-(void)importFreshData{
    FDAPIClient *webservice             = [[FDAPIClient alloc]init];
    MobiHelpDatabase *database = [[MobiHelpDatabase alloc] initWithContext:[[FDCoreDataCoordinator sharedInstance] getBackgroundContext]];
    NSManagedObjectContext *context      = database.context;
    FDCoreDataImporter *coreDataImporter = [[FDCoreDataImporter alloc] initWithContext:context webservice:webservice];
    ShowNetworkActivityIndicator();
    [coreDataImporter importAllNotesforTicketID:self.ticketID WithParam:nil completion:^(NSError *error) {
        if (!error) {
            FDLog(@"Polling Notes");
            [self handleTicketState];
        }else{
            FDLog(@"Polling notes failed because: %@",error);
        }
        HideNetworkActivityIndicator();
    }];
}

#pragma mark - Set Data Source

-(void)setDataSource{
    [self setUpCoreDataFetch];
}

-(void)setUpCoreDataFetch{
    self.coreDataFetchManager = [[FDCoreDataFetchManager alloc]initWithTableView:tableView withRowAnimation:UITableViewRowAnimationFade];
    self.coreDataFetchManager.fetchedResultsController = self.fetchResultsController;
    self.coreDataFetchManager.delegate = self;
}

-(void)showError:(NSError *)error{
    if ([error isKindOfClass:[FDError class]]) {
        FDError *MHError = (FDError *)error;
        if ([FDError isAppDisabledForError:MHError]) {
            [FDProgressHUD showErrorWithStatus:FDLocalizedString(@"app disabled error message")];
        }else if(MHError.code == MOBIHELP_ERROR_NETWORK_CONNECTIVITY){
            [FDProgressHUD showErrorWithStatus:FDLocalizedString(@"Network Error Message")];
        }else{
            [FDProgressHUD dismiss];
        }
    }else{
        [FDProgressHUD showErrorWithStatus:FDLocalizedString(@"Ticket Submission Error Text")];
    }
}

-(void)createNoteWithContent:(FDNoteContent *)noteContent andCompletion:(void (^)(NSError *))completion;{
    FDAPIClient *webservice             = [[FDAPIClient alloc]init];
    FDCoreDataImporter *coreDataImporter = [[FDCoreDataImporter alloc] initWithContext:self.database.context webservice:webservice];
    [FDProgressHUD showWithStatus:FDLocalizedString(@"Submitting HUD Text") maskType:FDProgressHUDMaskTypeClear];
    noteContent.body     = [FDUtilities sanitizeStringForUTF8:noteContent.body];
    NSDictionary *params = [self constructNoteParametersWithContent:noteContent];
    [coreDataImporter createNoteWithContent:noteContent andParam:params completion:^(NSError *error) { if(completion)completion(error); } ];
}

-(NSDictionary *)constructNoteParametersWithContent:(FDNoteContent *)content{
    return  @{
              @"helpdesk_note" : @{
                      @"private"     : @"false",
                      @"incoming"    : @"true",
                      @"source"      : MOBIHELP_CONSTANTS_NOTE_SOURCE,
                      @"note_body_attributes" : @{ @"body" : content.body }
                      }
              };
}

#pragma mark - Image Picker Delegates

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage * pickedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    FDAttachmentImageViewController *attachmentImageViewController = [[FDAttachmentImageViewController alloc] initWithPickedImage:pickedImage];
    attachmentImageViewController.delegate = self;
    [picker pushViewController:attachmentImageViewController animated:YES];
}

-(void)attachmentController:(FDAttachmentImageViewController *)controller didFinishEditingContent:(FDNoteContent *)content withCompletion:(void (^)(NSError *))completion{
    content.ticketID = self.ticketID;
    [self createNoteWithContent:content andCompletion:^(NSError *error) {
        if (completion) completion(error);
    }];
}

#pragma mark - Keyboard Delegates

-(void) keyboardWillShow:(NSNotification *)note{
    CGRect keyboardFrame = [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardRect = [self.view convertRect:keyboardFrame fromView:nil];
    CGFloat keyboardCoveredHeight = self.view.bounds.size.height - keyboardRect.origin.y;
    bottomViewBottomConstraint.constant = - keyboardCoveredHeight;
    keyBoardHeight = keyboardCoveredHeight;
    [self.view layoutIfNeeded];
    [self scrollTableViewToLastCell];
    [self.view layoutIfNeeded];
}

-(void) keyboardWillHide:(NSNotification *)note{
    NSTimeInterval animationDuration = [[note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    keyBoardHeight = 0.0;
    bottomViewBottomConstraint.constant = 0.0;
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (keyBoardHeight > 0) {
        [self scrollTableViewToLastCell];
    }
}

#pragma mark - Growing TextView Delegates

- (void)growingTextView:(FDGrowingTextView *)growingTextView willChangeHeight:(float)height{
    if (height > bottomViewHeightConstraint.constant) {
        bottomViewHeightConstraint.constant = height;
        bottomViewBottomConstraint.constant = - keyBoardHeight;
    }
    
    [self scrollTableViewToLastCell];
}

- (void)growingTextViewDidChange:(FDGrowingTextView *)growingTextView {
    if ([growingTextView.text isEqualToString:@""]) {

        //Reset toolbar height when there is no text
        bottomViewHeightConstraint.constant = TOOLBAR_HEIGHT;
        bottomViewBottomConstraint.constant = -keyBoardHeight;
    }
}

- (void)growingTextViewDidBeginEditing:(FDGrowingTextView *)growingTextView {
    [self scrollTableViewToLastCell];
}

-(void)navigationController:(UINavigationController *)navigationController
     willShowViewController:(UIViewController *)viewController
                   animated:(BOOL)animated
{
    
    BOOL isStatusBarHidden = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIStatusBarHidden"] boolValue];

    if (isStatusBarHidden == YES) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    }
}

-(BOOL)prefersStatusBarHidden  
{
    BOOL isStatusBarHidden = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIStatusBarHidden"] boolValue];
    return isStatusBarHidden;
}

- (void)receiveSolutionLinkTap:(NSString *)URLString {
    FDArticleDetailViewController *articleDetailViewController = [[FDArticleDetailViewController alloc] init];
    NSNumber *solutionArticleID = [self getArticleIDFromURL:URLString];
    FDArticle *article = [FDArticle getArticleWithID:solutionArticleID inManagedObjectContext:self.database.context];
    if (!article.articleID) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URLString]];
    }else {
        articleDetailViewController.articleDescription = article.articleDescription;
        [self.navigationController pushViewController:articleDetailViewController animated:YES];
    }
}

- (NSNumber *)getArticleIDFromURL:(NSString *)URLString {
    NSString *numberString;
    NSScanner *scanner = [NSScanner scannerWithString:URLString];
    NSCharacterSet *numbers = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
    [scanner scanCharactersFromSet:numbers intoString:&numberString];
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *articleIDasNumber = [formatter numberFromString:numberString];

    return articleIDasNumber;
}

#pragma mark - Ticket state displayer

-(void)displayPromptView:(FDPromptView *)promptView{
    [self dismissKeyboard];
    [self updateBottomViewWith:promptView andHeight:PROMPT_VIEW_HEIGHT];

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self scrollTableViewToLastCell];
    });
}

-(void)clearPromptView:(FDPromptView *)promptView{
    [self updateBottomViewWith:self.inputToolbar andHeight:TOOLBAR_HEIGHT];
}

-(void)ticketStateOnResolved{
    FDAPIClient *webservice         = [[FDAPIClient alloc]init];
    FDCoreDataImporter *importer = [[FDCoreDataImporter alloc] initWithContext:self.database.context webservice:webservice];
    [FDProgressHUD show];
    [importer closeTicketWithID:self.ticketID completion:^(NSError *error) {
        if (!error) {
            [self.ticketStateDisplayer handleTicketState:MOBIHELP_TICKET_STATUS_CLOSED];
            [FDProgressHUD dismiss];
        }else{
            [FDProgressHUD showErrorWithStatus:FDLocalizedString(@"Network Error Message")];
        }
    }];
}

-(void)ticketStateOnNotResolved{
    [self.ticketStateDisplayer handleTicketState:MOBIHELP_TICKET_STATUS_OPEN];
    self.ticketStateDisplayer.ignorePrompts = YES;
}

-(void)ticketStateOnInitiateNewConversation{
    NSArray *viewControllers = self.navigationController.viewControllers;
    UIViewController *previousController = viewControllers[viewControllers.count -2];
    if([previousController isKindOfClass:[FDTicketListViewController class]]){
        [self.navigationController popViewControllerAnimated:NO];
        FDTicketListViewController *ticketController = (FDTicketListViewController *)previousController;
        [ticketController createNewTicketButtonAction:nil];
    }
}

-(void)dealloc{
    [self localNotificationUnSubscription];
}

#pragma mark Input toolbar delegate

-(void)inputToolbarAttachmentButtonPressed:(id)sender{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate      = self;
    picker.allowsEditing = NO;
    picker.sourceType    = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.view.backgroundColor = [self.theme backgroundColorSDK];
    [FDProgressHUD show];
    [self presentViewController:picker animated:YES completion:^{[FDProgressHUD dismiss];}];
}

-(void)inputToolbarSendButtonPressed:(id)sender{
    [self startPoller];
    FDNoteContent *noteContent = [[FDNoteContent alloc]init];
    noteContent.body           = trimString(self.inputToolbar.textView.text);
    noteContent.ticketID       = self.ticketID;
    if ([noteContent.body length] > 0) {
        [self.inputToolbar enableSendButton:NO];
        [self createNoteWithContent:noteContent andCompletion:^(NSError *error) {
            [self.inputToolbar enableSendButton:YES];
            if (error) {
                self.inputToolbar.textView.text = noteContent.body;
                FDLog(@"Could not send note %@",error);
                [self showError:error];
            }else{
                [self scrollTableViewToLastCell];
                [FDProgressHUD dismiss];
            }
        }];
    }
    self.inputToolbar.textView.text = @"";

    //Reset tool bar height after pressing send button
    bottomViewHeightConstraint.constant = TOOLBAR_HEIGHT;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [UIView animateWithDuration:0.3 animations:^{
        [self dismissKeyboard];
    }];
}

@end