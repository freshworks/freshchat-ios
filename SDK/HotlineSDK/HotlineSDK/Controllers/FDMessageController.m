//
//  FDMessageController.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 27/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDMessageController.h"
#import "FDMessageCell.h"
#import "Konotor.h"
#import "KonotorImageInput.h"
#import "Hotline.h"

@interface FDMessageController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *messages;
@property (nonatomic, strong) HLChannel *channel;
@property (nonatomic, strong) FDInputToolbarView *inputToolbar;
@property (strong, nonatomic) NSLayoutConstraint *bottomViewHeightConstraint;
@property (strong, nonatomic) NSLayoutConstraint *bottomViewBottomConstraint;
@property (strong, nonatomic) UIView *bottomView;
@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic) BOOL isKeyboardOpen;
@property (nonatomic) BOOL isModalPresentationPreferred;
@property (nonatomic, strong) UIImage *sentImage;

@end

@implementation FDMessageController

static BOOL loading = NO;
static BOOL showingAlert = NO;
static BOOL promptForPush = YES;
BOOL firstWordOnLine=YES;

static int messageCount = 0;
static int messageCount_prev = 0;
static CGFloat TOOLBAR_HEIGHT = 40;

-(instancetype)initWithChannel:(HLChannel *)channel andPresentModally:(BOOL)isModal{
    self = [super init];
    if (self) {
        self.channel = channel;
        self.isModalPresentationPreferred = isModal;
        [Konotor setDelegate:self];
        self.sentImage=[UIImage imageNamed:@"konotor_sent.png"];
    }
    return self;
}

-(void)willMoveToParentViewController:(UIViewController *)parent{
    parent.title = @"Messages";
    self.view.backgroundColor = [UIColor whiteColor];
    [self setSubviews];
    [self updateMessages];
    [self setNavigationItem];
    [self localNotificationSubscription];
    [self scrollTableViewToLastCell];
}

-(void)setNavigationItem{
    if(self.isModalPresentationPreferred){
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(closeButtonAction:)];
        [self.parentViewController.navigationItem setLeftBarButtonItem:closeButton];
    }else{
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BackArrow"]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self.navigationController
                                                                      action:@selector(popViewControllerAnimated:)];
        self.parentViewController.navigationItem.leftBarButtonItem = backButton;
    }
    
    UIBarButtonItem *FAQButton = [[UIBarButtonItem alloc]initWithTitle:@"FAQ" style:UIBarButtonItemStylePlain target:self action:@selector(FAQButtonAction:)];
    self.parentViewController.navigationItem.rightBarButtonItem = FAQButton;
}

-(void)FAQButtonAction:(id)sender{
    [[Hotline sharedInstance]presentSolutions:self];
}

-(void)closeButtonAction:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)updateMessages{
    NSSortDescriptor* desc=[[NSSortDescriptor alloc] initWithKey:@"createdMillis" ascending:YES];
    self.messages=[[Konotor getAllMessagesForDefaultConversation] sortedArrayUsingDescriptors:[NSArray arrayWithObject:desc]];
    messageCount=(int)[self.messages count];
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
                                                               constant:TOOLBAR_HEIGHT];
    
    self.bottomViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.bottomView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0 constant:0];
    
    self.inputToolbar = [[FDInputToolbarView alloc]initWithDelegate:self];
    self.inputToolbar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.inputToolbar showAttachButton:YES];

    //Initial Constraints
    NSDictionary *views = @{@"tableView" : self.tableView, @"bottomView" : self.bottomView};
    [self.view addConstraint:self.bottomViewBottomConstraint];
    [self.view addConstraint:self.bottomViewHeightConstraint];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bottomView]|" options:0 metrics:nil views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView][bottomView]" options:0 metrics:nil views:views]];
    
    [self updateBottomViewWith:self.inputToolbar andHeight:TOOLBAR_HEIGHT];
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
    }
    if (indexPath.row < self.messages.count) {
        KonotorMessageData *message = self.messages[indexPath.row];
        [cell drawMessageViewForMessage:message parentView:self.view];
    }
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.messages.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    KonotorMessageData *message = self.messages[indexPath.row];
    float height = [FDMessageCell getHeightForMessage:message parentView:self.view];
    return height;
}

-(void)inputToolbar:(FDInputToolbarView *)toolbar attachmentButtonPressed:(id)sender{
    [self.view endEditing:YES];
    [KonotorImageInput showInputOptions:self];
}

-(void)inputToolbar:(FDInputToolbarView *)toolbar micButtonPressed:(id)sender{
    NSLog(@"Mic button pressed");
}

-(void)inputToolbar:(FDInputToolbarView *)toolbar sendButtonPressed:(id)sender{
    
    NSCharacterSet *trimChars = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *toSend = [self.inputToolbar.textView.text stringByTrimmingCharactersInSet:trimChars];
    if((![KonotorUIParameters sharedInstance].allowSendingEmptyMessage)&&[toSend isEqualToString:@""]){
        UIAlertView* alertNilString=[[UIAlertView alloc] initWithTitle:@"Empty Message" message:@"You cannot send an empty message. Please type a message to send." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertNilString show];
    }else{
        [Konotor uploadTextFeedback:toSend];
        BOOL notificationEnabled=NO;
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
            if(promptForPush){
                UIAlertView* pushDisabledAlert=[[UIAlertView alloc] initWithTitle:@"Modify Push Setting" message:@"To be notified of responses even when out of this chat, enable push notifications for this app via the Settings->Notification Center" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [pushDisabledAlert show];
                promptForPush=NO;
            }
        }
        
        self.inputToolbar.textView.text = @"";

        [self inputToolbar:toolbar textViewDidChange:toolbar.textView];
        
    }
    [self refreshView];
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
}

-(void)localNotificationUnSubscription{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)handleBecameActive:(NSNotification *)notification{

}

-(void)handleEnteredBackground:(NSNotification *)notification{
    
}

#pragma mark Keyboard delegate

-(void) keyboardWillShow:(NSNotification *)note{
    NSTimeInterval animationDuration = [[note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    self.isKeyboardOpen = YES;
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
    self.isKeyboardOpen = NO;
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
        if(firstWordOnLine==YES){
            firstWordOnLine=NO;
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
    textView.frame=CGRectMake(textView.frame.origin.x,textView.frame.origin.y,textView.frame.size.width,height);
    [self scrollTableViewToLastCell];
   
}

-(void)scrollTableViewToLastCell{
    int lastSpot=loading?messageCount:(messageCount-1);
    
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

#pragma mark Konotor delegates

- (void) didFinishPlaying:(NSString *)messageID{
    for(UITableViewCell* cell in [self.tableView visibleCells]){
        KonotorMediaUIButton* button=(KonotorMediaUIButton*)[cell viewWithTag:KONOTOR_PLAYBUTTON_TAG];
        if([button.messageID isEqualToString:messageID]){
            [button stopAnimating];
        }
    }
}

- (void) didStartPlaying:(NSString *)messageID{
    for(UITableViewCell* cell in [self.tableView visibleCells]){
        KonotorMediaUIButton* button=(KonotorMediaUIButton*)[cell viewWithTag:KONOTOR_PLAYBUTTON_TAG];
        if([button.messageID isEqualToString:messageID]){
            [button startAnimating];
        }
    }
}

- (void) didFinishDownloadingMessages{
    if((loading)||([[Konotor getAllMessagesForDefaultConversation] count]>messageCount_prev)){
        loading=NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Konotor_FinishedMessagePull" object:nil];
        [self refreshView];
    }
}

- (void) didFinishUploading:(NSString *)messageID{
    for(FDMessageCell* cell in [self.tableView visibleCells]){
        if([messageID hash]==cell.tag){
            UIImageView* uploadStatus=(UIImageView*)cell.uploadStatusImageView;
            [uploadStatus setImage:self.sentImage];
            for(int i=messageCount-1;i>=0;i--){
                if([(NSString*)[(KonotorMessageData*)[self.messages objectAtIndex:i] messageId] isEqualToString:messageID]){
                    [(KonotorMessageData*)[self.messages objectAtIndex:i] setUploadStatus:([NSNumber numberWithInt:MessageUploaded])];
                    break;
                }
            }
        }
    }
}

- (void) didEncounterErrorWhileUploading:(NSString *)messageID{
    if(!showingAlert){
        UIAlertView* konotorAlert=[[UIAlertView alloc] initWithTitle:@"Message not sent" message:@"We could not send your message(s) at this time. Check your internet or try later." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [konotorAlert show];
        showingAlert=YES;
    }
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    showingAlert=NO;
}


- (void) didEncounterErrorWhileDownloading:(NSString *)messageID{
    //Show Toast
}

-(void) didEncounterErrorWhileDownloadingConversations{
    if((loading)||([[Konotor getAllMessagesForDefaultConversation] count]>messageCount_prev)){
        loading=NO;
        [self refreshView];
    }
}

-(BOOL) handleRemoteNotification:(NSDictionary*)userInfo withShowScreen:(BOOL) showScreen{
    NSString* marketingId=((NSString*)[userInfo objectForKey:@"kon_message_marketingid"]);
    NSString* url=[userInfo valueForKey:@"kon_m_url"];
    if(showScreen&&marketingId&&([marketingId longLongValue]!=0))
        [Konotor MarkMarketingMessageAsClicked:[NSNumber numberWithLongLong:[marketingId longLongValue]]];
    if(showScreen&&(url!=nil)){
        @try{
            NSURL *clickUrl=[NSURL URLWithString:url];
            if([[UIApplication sharedApplication] canOpenURL:clickUrl]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] openURL:clickUrl];
                });
            }
        }
        @catch(NSException *e){
            NSLog(@"%@",e);
        }
        [Konotor DownloadAllMessages];
        return YES;
    }else{
        if(!([(NSString*)[userInfo valueForKey:@"source"] isEqualToString:@"konotor"])){
            return NO;
        }
        loading = YES;
        [Konotor DownloadAllMessages];
        
        [self.tableView reloadData];
        return YES;
    }
    return YES;
}

- (void) refreshView{
    messageCount_prev=(int)[[Konotor getAllMessagesForDefaultConversation] count];
    NSSortDescriptor* desc=[[NSSortDescriptor alloc] initWithKey:@"createdMillis" ascending:YES];
    self.messages=[[Konotor getAllMessagesForDefaultConversation] sortedArrayUsingDescriptors:[NSArray arrayWithObject:desc]];
    messageCount=(int)[self.messages count];
    
    [self.tableView reloadData];
    [Konotor markAllMessagesAsRead];
    [self scrollTableViewToLastCell];
}


#pragma Scrollview delegates

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint fingerLocation = [scrollView.panGestureRecognizer locationInView:scrollView];
    CGPoint absoluteFingerLocation = [scrollView convertPoint:fingerLocation toView:self.view];
    NSInteger keyboardOffsetFromBottom = self.view.frame.size.height - absoluteFingerLocation.y;
    
    if (self.isKeyboardOpen && scrollView.panGestureRecognizer.state == UIGestureRecognizerStateChanged && absoluteFingerLocation.y >= (self.view.frame.size.height - self.keyboardHeight)) {
        self.bottomViewBottomConstraint.constant = -keyboardOffsetFromBottom;
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.tableView reloadData];
    [self scrollTableViewToLastCell];
}

-(void)dealloc{
    [self localNotificationUnSubscription];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    KonotorMessageData *message = self.messages[indexPath.row];
    NSLog(@"Message type :%@",message.messageType);
}

@end