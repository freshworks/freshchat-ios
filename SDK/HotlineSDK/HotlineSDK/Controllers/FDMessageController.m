//
//  FDMessageController.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 27/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDMessageController.h"
#import "FDMessageCell.h"
#import "KonotorImageInput.h"
#import "Hotline.h"
#import "KonotorMessage.h"
#import "Konotor.h"
#import "HLMacros.h"
#import "FDLocalNotification.h"
#import "FDAudioMessageInputView.h"
#import "HLConstants.h"
#import "HLArticle.h"
#import "HLArticleDetailViewController.h"
#import "HLArticlesController.h"
#import "HLContainerController.h"
#import "HLLocalization.h"
#import "HLTheme.h"
#import "FDUtilities.h"

typedef struct {
    BOOL isLoading;
    BOOL isShowingAlert;
    BOOL canPromptForPush;
    BOOL isFirstWordOnLine;
    BOOL isKeyboardOpen;
    BOOL isModalPresentationPreferred;
} FDMessageControllerFlags;

@interface FDMessageController () <UITableViewDelegate, UITableViewDataSource, FDMessageCellDelegate, FDAudioInputDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *messages;
@property (nonatomic, strong) HLChannel *channel;
@property (nonatomic, strong) FDInputToolbarView *inputToolbar;
@property (nonatomic, strong) FDAudioMessageInputView *audioMessageInputView;
@property (nonatomic, strong) NSLayoutConstraint *bottomViewHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *bottomViewBottomConstraint;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UIImage *sentImage;
@property (nonatomic, strong) KonotorConversation *conversation;
@property (nonatomic, strong) KonotorImageInput *imageInput;
@property (nonatomic, strong) NSTimer *pollingTimer;
@property (nonatomic, strong) NSString* currentRecordingMessageId;
@property (nonatomic, strong) NSMutableDictionary* messageHeightMap;
@property (nonatomic, strong) NSMutableDictionary* messageWidthMap;
@property (nonatomic, assign) FDMessageControllerFlags flags;

@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic) NSInteger messageCount;
@property (nonatomic) NSInteger messageCountPrevious;
@property (nonatomic) NSInteger messagesDisplayedCount;
@property (nonatomic) NSInteger loadmoreCount;

@end

@implementation FDMessageController

static CGFloat INPUT_TOOLBAR_HEIGHT = 40;

-(instancetype)initWithChannel:(HLChannel *)channel andPresentModally:(BOOL)isModal{
    self = [super init];
    if (self) {
        self.messageHeightMap = [[NSMutableDictionary alloc]init];
        self.messageWidthMap = [[NSMutableDictionary alloc]init];
        
        _flags.canPromptForPush = YES;
        _flags.isFirstWordOnLine = YES;
        _flags.isModalPresentationPreferred = isModal;

        self.messageCount = 0;
        self.messageCountPrevious = 0;
        self.messagesDisplayedCount=20;
        self.loadmoreCount=20;
        
        self.channel = channel;
        self.imageInput = [[KonotorImageInput alloc]initWithConversation:self.conversation onChannel:self.channel];
        [Konotor setDelegate:self];
    }
    return self;
}

-(KonotorConversation *)conversation{
    if(!_conversation){
        _conversation = [_channel primaryConversation];
    }
    return _conversation;
}

-(void)willMoveToParentViewController:(UIViewController *)parent{
    parent.title = @"Messages";
    self.messagesDisplayedCount = 20;
    self.view.backgroundColor = [UIColor whiteColor];
    [self setSubviews];
    [self updateMessages];
    [self setNavigationItem];
    [self localNotificationSubscription];
    [self scrollTableViewToLastCell];
    [KonotorConversation DownloadAllMessages];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self startPoller];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self cancelPoller];
}

-(void)startPoller{
    if(![self.pollingTimer isValid]){
        self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(pollMessages:)
                                                           userInfo:nil repeats:YES];
        FDLog(@"Starting Poller");
    }
}

-(void)cancelPoller{
    if([self.pollingTimer isValid]){
        [self.pollingTimer invalidate];
        FDLog(@"Cancelled Poller");
    }
}

-(void)pollMessages:(NSTimer *)timer{
    [KonotorConversation DownloadAllMessages];
}

-(void)setNavigationItem{
    if(_flags.isModalPresentationPreferred){
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc]initWithTitle:HLLocalizedString(LOC_MESSAGES_CLOSE_BUTTON_TEXT)  style:UIBarButtonItemStylePlain target:self action:@selector(closeButtonAction:)];
        [self.parentViewController.navigationItem setLeftBarButtonItem:closeButton];
    }else{
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[[HLTheme sharedInstance] getImageWithKey:IMAGE_BACK_BUTTON]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self.navigationController
                                                                      action:@selector(popViewControllerAnimated:)];
        self.parentViewController.navigationItem.leftBarButtonItem = backButton;
    }
    
    UIBarButtonItem *FAQButton = [[UIBarButtonItem alloc]initWithTitle:HLLocalizedString(LOC_FAQ_TITLE_TEXT) style:UIBarButtonItemStylePlain target:self action:@selector(FAQButtonAction:)];
    self.parentViewController.navigationItem.rightBarButtonItem = FAQButton;
    
    if (self.parentViewController) {
        self.parentViewController.navigationController.interactivePopGestureRecognizer.delegate = self;
    }else{
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
}

-(void)FAQButtonAction:(id)sender{
    [[Hotline sharedInstance]presentSolutions:self];
}

-(void)closeButtonAction:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)setSubviews{
    self.tableView = [[UITableView alloc]init];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.separatorStyle=UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    
    //Bottomview
    self.bottomView = [[UIView alloc]init];
    self.bottomView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.bottomView];
    
    self.bottomViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.bottomView
                                                              attribute:NSLayoutAttributeHeight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:nil
                                                              attribute:NSLayoutAttributeNotAnAttribute
                                                             multiplier:1.0
                                                               constant:0];
    
    self.bottomViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.bottomView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0 constant:0];

    //Initial Constraints
    NSDictionary *views = @{@"tableView" : self.tableView, @"bottomView" : self.bottomView};
    [self.view addConstraint:self.bottomViewBottomConstraint];
    [self.view addConstraint:self.bottomViewHeightConstraint];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bottomView]|" options:0 metrics:nil views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView][bottomView]" options:0 metrics:nil views:views]];
    
    if([self.channel.type isEqualToString:CHANNEL_TYPE_BOTH]){
        
        self.inputToolbar = [[FDInputToolbarView alloc]initWithDelegate:self];
        self.inputToolbar.translatesAutoresizingMaskIntoConstraints = NO;
        [self.inputToolbar showAttachButton:YES];
        
        self.audioMessageInputView = [[FDAudioMessageInputView alloc] initWithDelegate:self];
        self.audioMessageInputView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self updateBottomViewWith:self.inputToolbar andHeight:INPUT_TOOLBAR_HEIGHT];
    }
}

-(void)updateBottomViewWith:(UIView *)view andHeight:(CGFloat) height{
    [[self.bottomView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    [self.bottomView addSubview:view];
    self.bottomViewHeightConstraint.constant = height;
    
    NSDictionary *views = @{ @"bottomInputView" : view };
    [self.bottomView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bottomInputView]|" options:0 metrics:nil views:views]];
    [self.bottomView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[bottomInputView]|" options:0 metrics:nil views:views]];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = @"FDMessageCell";
    FDMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[FDMessageCell alloc] initWithReuseIdentifier:cellIdentifier];
        cell.delegate = self;
    }
    if (indexPath.row < self.messages.count) {
        KonotorMessageData *message = self.messages[(self.messageCount - self.messagesDisplayedCount)+indexPath.row];
        cell.messageData = message;
        [cell drawMessageViewForMessage:message parentView:self.view withWidth:[self getWidthForMessage:message]];
    }
    if(indexPath.row==0 && self.messagesDisplayedCount<self.messages.count){
        UITableViewCell* cell=[self getRefreshStatusCell];
        NSInteger oldnumber = self.messagesDisplayedCount;
        self.messagesDisplayedCount += self.loadmoreCount;
        if(self.messagesDisplayedCount > self.messageCount){
            self.messagesDisplayedCount = self.messageCount;
        }
        [self performSelector:@selector(refreshView:) withObject:@(oldnumber) afterDelay:0];
        return cell;
    }
    return cell;
}

- (UITableViewCell*) getRefreshStatusCell
{
    static NSString *CellIdentifier = @"KonotorRefreshCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(cell==nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    [cell setBackgroundColor:[UIColor clearColor]];
    UIActivityIndicatorView* refreshIndicator=(UIActivityIndicatorView*)[cell viewWithTag:KONOTOR_REFRESHINDICATOR_TAG];
    if(refreshIndicator==nil){
        refreshIndicator=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [refreshIndicator setFrame:CGRectMake(self.view.frame.size.width/2-10, cell.contentView.frame.size.height/2-10, 20, 20)];
        refreshIndicator.tag=KONOTOR_REFRESHINDICATOR_TAG;
        [cell.contentView addSubview:refreshIndicator];
    }
    if(![refreshIndicator isAnimating])
        [refreshIndicator startAnimating];
    
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.messagesDisplayedCount;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    KonotorMessageData *message = self.messages[(self.messageCount - self.messagesDisplayedCount)+indexPath.row];
    float height;
    NSString *key = [self getIdentityForMessage:message];
    if(self.messageHeightMap[key]){
        height = [self.messageHeightMap[key] floatValue];
    }
    else {
        height = [FDMessageCell getHeightForMessage:message parentView:self.view];
        if(![message.createdMillis integerValue]){
            height = height - 16;
        }//TODO: Give names to all the numeric contants used in code. Hard to understand what 
        // this 16 is . And there are too many 16s in the code base - Rex
        self.messageHeightMap[key] = @(height);
    }
    return height;
}


-(CGFloat)getWidthForMessage:(KonotorMessageData *) message{
    float width;
    NSString *key = [self getIdentityForMessage:message];
    if(self.messageWidthMap[key]){
        width = [self.messageWidthMap[key] floatValue];
    }
    else {
        width = [FDMessageCell getWidthForMessage:message];
        self.messageWidthMap[key] = @(width);
    }
    return width;
}


-(NSString *)getIdentityForMessage:(KonotorMessageData *)message{
    return ((message.messageId==nil)?[NSString stringWithFormat:@"%ul",message.createdMillis.intValue]:message.messageId);
    //[FDUtilities getKeyForObject:message];
}

-(void)inputToolbar:(FDInputToolbarView *)toolbar attachmentButtonPressed:(id)sender{
    [self.view endEditing:YES];
    [self.imageInput showInputOptions:self];
}

-(void)inputToolbar:(FDInputToolbarView *)toolbar micButtonPressed:(id)sender{
    BOOL recording=[Konotor startRecording];
    if(recording){
        [self updateBottomViewWith:self.audioMessageInputView andHeight:INPUT_TOOLBAR_HEIGHT];
    }
    NSLog(@"Mic button pressed");
}

-(void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message{
    UIAlertView *alert=[[UIAlertView alloc] initWithTitle:title message:message delegate:self
                                        cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

-(void)inputToolbar:(FDInputToolbarView *)toolbar sendButtonPressed:(id)sender{
    NSCharacterSet *trimChars = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *toSend = [self.inputToolbar.textView.text stringByTrimmingCharactersInSet:trimChars];
    if([toSend isEqualToString:@""]){
        [self showAlertWithTitle:HLLocalizedString(LOC_EMPTY_MSG_TITLE) andMessage:HLLocalizedString(LOC_EMPTY_MSG_INFO_TEXT)];
    }else{
        [Konotor uploadTextFeedback:toSend onConversation:self.conversation onChannel:self.channel];
        [self checkPushNotificationState];
        self.inputToolbar.textView.text = @"";
        [self inputToolbar:toolbar textViewDidChange:toolbar.textView];
    }
    [self refreshView];
}

-(void)checkPushNotificationState{
    BOOL notificationEnabled = NO;
#if(__IPHONE_OS_VERSION_MAX_ALLOWED >=80000)
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")){
        notificationEnabled=[[UIApplication sharedApplication] isRegisteredForRemoteNotifications];
    }
    else
#endif
    {
#if (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0)
        UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
        if(types != UIRemoteNotificationTypeNone) notificationEnabled=YES;
#endif
    }
    
    if (!notificationEnabled) {
        if(_flags.canPromptForPush){
            [self showAlertWithTitle:HLLocalizedString(LOC_MODIFY_PUSH_SETTING_TITLE)
                          andMessage:HLLocalizedString(LOC_MODIFY_PUSH_SETTING_INFO_TEXT)];
            _flags.canPromptForPush = NO;
        }
    }
}


-(void)localNotificationSubscription{
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
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
    
    [[NSNotificationCenter defaultCenter]addObserverForName:HOTLINE_NETWORK_REACHABLE object:nil
                                                      queue:nil usingBlock:^(NSNotification *note) {
         [KonotorMessage uploadAllUnuploadedMessages];
    }];
}

-(void)localNotificationUnSubscription{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)handleBecameActive:(NSNotification *)notification{
    [self startPoller];
}

-(void)handleEnteredBackground:(NSNotification *)notification{
    [self cancelPoller];
}

#pragma mark Keyboard delegate

-(void) keyboardWillShow:(NSNotification *)note{
    NSTimeInterval animationDuration = [[note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    _flags.isKeyboardOpen = YES;
    CGRect keyboardFrame = [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardRect = [self.view convertRect:keyboardFrame fromView:nil];
    CGFloat keyboardCoveredHeight = self.view.bounds.size.height - keyboardRect.origin.y;
    self.bottomViewBottomConstraint.constant = - keyboardCoveredHeight;
    self.keyboardHeight = keyboardCoveredHeight;
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
    [self scrollTableViewToLastCell];
}

-(void) keyboardWillHide:(NSNotification *)note{
    _flags.isKeyboardOpen = NO;
    NSTimeInterval animationDuration = [[note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    self.keyboardHeight = 0.0;
    self.bottomViewBottomConstraint.constant = 0.0;
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}

#pragma mark Text view delegates

-(void)inputToolbar:(FDInputToolbarView *)toolbar textViewDidChange:(UITextView *)textView{    
    
    CGSize txtSize = [textView sizeThatFits:CGSizeMake(textView.frame.size.width, 140)];
    float height=txtSize.height;
    if((height)>=67){
        height=67;
        if(_flags.isFirstWordOnLine == YES){
            _flags.isFirstWordOnLine = NO;
        }else{
            textView.scrollEnabled=YES;
        }
    }
    else{
        textView.scrollEnabled=NO;
    }
    
    if (height > self.bottomViewHeightConstraint.constant) {
        self.bottomViewHeightConstraint.constant = height+10; //Fix this
        self.bottomViewBottomConstraint.constant = - self.keyboardHeight;
    }
    else{
        self.bottomViewHeightConstraint.constant = height+10; //Fix this
        self.bottomViewBottomConstraint.constant = - self.keyboardHeight;
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        textView.frame=CGRectMake(textView.frame.origin.x,textView.frame.origin.y,textView.frame.size.width,height);
        [self scrollTableViewToLastCell];

    }];
    
}

-(void)scrollTableViewToLastCell{

     NSInteger lastSpot = _flags.isLoading ? self.messagesDisplayedCount : (self.messagesDisplayedCount-1);
    
    if(lastSpot<0) return;
    
    NSIndexPath *indexPath=[NSIndexPath indexPathForRow:lastSpot inSection:0];
    @try {
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }
    @catch (NSException *exception ) {
        indexPath=[NSIndexPath indexPathForRow:(indexPath.row-1) inSection:0];
        @try{
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        }
        @catch(NSException *exception){
        }
    }
}

-(void)scrollTableViewToCell:(int)lastSpot{
    
    if(lastSpot<0) return;
    NSIndexPath *indexPath=[NSIndexPath indexPathForRow:(self.messagesDisplayedCount-lastSpot) inSection:0];
    @try {
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    @catch (NSException *exception ) {
        indexPath=[NSIndexPath indexPathForRow:(indexPath.row-1) inSection:0];
        @try{
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
        @catch(NSException *exception){
            
        }
    }
}

#pragma mark Konotor delegates

- (void) didStartUploadingNewMessage{
    [self refreshView];
}

- (void) didFinishDownloadingMessages{
    NSInteger count = [self fetchMessages].count;
    if( _flags.isLoading || (count > self.messageCountPrevious) ){
        FDLog(@"Refreshing view to show new message");
        _flags.isLoading = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Konotor_FinishedMessagePull" object:nil];
        [self refreshView];
    }
}

- (void) didFinishUploading:(NSString *)messageID{
    [self refreshView];
}

- (void) didEncounterErrorWhileUploading:(NSString *)messageID{
    if(!_flags.isShowingAlert){
        [self showAlertWithTitle:HLLocalizedString(LOC_MESSAGE_UNSENT_TITLE)
                      andMessage:HLLocalizedString(LOC_MESSAGE_UNSENT_INFO_TEXT)];
        _flags.isShowingAlert = YES;
    }
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    _flags.isShowingAlert = NO;
}

- (void) didEncounterErrorWhileDownloading:(NSString *)messageID{
    //Show Toast
}

-(void) didEncounterErrorWhileDownloadingConversations{
    NSInteger count = [self fetchMessages].count;
    if(( _flags.isLoading )||(count > self.messageCountPrevious)){
        _flags.isLoading = NO;
        [self refreshView];
    }
}

-(void)updateMessages{
    self.messages = [self fetchMessages];
    self.messageCount=(int)[self.messages count];
    if((self.messagesDisplayedCount > self.messageCount)||
       (self.messageCount<=KONOTOR_MESSAGESPERPAGE)||
       ((self.messageCount - self.messagesDisplayedCount)<3)){
        
        self.messagesDisplayedCount = self.messageCount;
    }
}
- (void) refreshView{
    [self refreshView:nil];

}

- (void) refreshView:(id)obj{
    self.messageCountPrevious=(int)self.messages.count;
    self.messages = [self fetchMessages];
    self.messageCount=(int)[self.messages count];
    if((self.messagesDisplayedCount > self.messageCount)||
       (self.messageCount<=KONOTOR_MESSAGESPERPAGE)||
       ((self.messageCount - self.messagesDisplayedCount)<3)){
        self.messagesDisplayedCount = self.messageCount;
    }

    [self.tableView reloadData];
    [Konotor markAllMessagesAsRead];
    if(obj==nil)
        [self scrollTableViewToLastCell];
    else{
        [self scrollTableViewToCell:((NSNumber*)obj).intValue];
    }
}

-(NSArray *)fetchMessages{
    NSSortDescriptor* desc=[[NSSortDescriptor alloc] initWithKey:@"createdMillis" ascending:YES];
    NSArray *messages = [KonotorMessage getAllMesssageForChannel:self.channel];
    return [messages sortedArrayUsingDescriptors:@[desc]];
}

#pragma Scrollview delegates

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (_flags.isKeyboardOpen){
        CGPoint fingerLocation = [scrollView.panGestureRecognizer locationInView:scrollView];
        CGPoint absoluteFingerLocation = [scrollView convertPoint:fingerLocation toView:self.view];
        float viewFrameHeight = self.view.frame.size.height;
        NSInteger keyboardOffsetFromBottom = viewFrameHeight - absoluteFingerLocation.y;
        
        if (scrollView.panGestureRecognizer.state == UIGestureRecognizerStateChanged
            && absoluteFingerLocation.y >= (viewFrameHeight - self.keyboardHeight)) {
            self.bottomViewBottomConstraint.constant = -keyboardOffsetFromBottom;
        }
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.tableView reloadData];
    [self inputToolbar:self.inputToolbar textViewDidChange:self.inputToolbar.textView];
    [self scrollTableViewToLastCell];
}

#pragma mark - Message cell delegates


-(void)messageCell:(FDMessageCell *)cell pictureTapped:(UIImage *)image{
    FDLog(@"Picture message tapped");
}

-(void) openActionUrl:(id) sender{
    FDActionButton* button=(FDActionButton*)sender;
    if(button.articleID!=nil && button.articleID > 0){
        @try{
            HLArticle *article = [HLArticle getWithID:button.articleID inContext:[KonotorDataManager sharedInstance].mainObjectContext];
            if(article!=nil){
                HLArticleDetailViewController* articleDetailController=[[HLArticleDetailViewController alloc] init];
                articleDetailController.articleID = article.articleID;
                articleDetailController.articleTitle = article.title;
                articleDetailController.articleDescription = article.articleDescription;
                articleDetailController.categoryTitle=article.category.title;
                articleDetailController.categoryID = article.categoryID;
                HLContainerController *container = [[HLContainerController alloc]initWithController:articleDetailController];
                [self.navigationController pushViewController:container animated:YES];
            }
        }
        @catch(NSException* e){
            NSLog(@"%@",e);
        }
    }
    else if(button.actionUrlString!=nil){
        @try{
            NSURL * actionUrl=[NSURL URLWithString:button.actionUrlString];
            if([[UIApplication sharedApplication] canOpenURL:actionUrl]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] openURL:actionUrl];
                });
            }
        }
        @catch(NSException* e){
            NSLog(@"%@",e);
        }
    }
}

#pragma mark - Audio toolbar delegates

-(void)audioMessageInput:(FDAudioMessageInputView *)toolbar dismissButtonPressed:(id)sender{
    [Konotor cancelRecording];
    [self updateBottomViewWith:self.inputToolbar andHeight:INPUT_TOOLBAR_HEIGHT];
}

-(void) audioMessageInput:(FDAudioMessageInputView *)toolbar stopButtonPressed:(id)sender{
    self.currentRecordingMessageId=[Konotor stopRecording];
}

-(void)audioMessageInput:(FDAudioMessageInputView *)toolbar sendButtonPressed:(id)sender{
    self.currentRecordingMessageId=[Konotor stopRecordingOnConversation:self.conversation];
    if(self.currentRecordingMessageId!=nil){
        [Konotor uploadVoiceRecordingWithMessageID:self.currentRecordingMessageId toConversationID:([self.conversation conversationAlias]) onChannel:self.channel];
    }
    [self updateBottomViewWith:self.inputToolbar andHeight:INPUT_TOOLBAR_HEIGHT];
}

-(void)dealloc{
    [self localNotificationUnSubscription];
}

@end