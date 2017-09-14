//
//  FDMessageController.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 27/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "FDMessageController.h"
#import "HLAgentMessageCell.h"
#import "HLUserMessageCell.h"
#import "KonotorImageInput.h"
#import "Freshchat.h"
#import "KonotorMessage.h"
#import "Message.h"
#import "Konotor.h"
#import "HLMacros.h"
#import "FDLocalNotification.h"
#import "FDAudioMessageInputView.h"
#import "HLConstants.h"
#import "HLArticle.h"
#import "HLArticlesController.h"
#import "HLContainerController.h"
#import "HLLocalization.h"
#import "HLTheme.h"
#import "FDUtilities.h"
#import "FDImagePreviewController.h"
#import "HLMessageServices.h"
#import "HotlineAppState.h"
#import "FDBarButtonItem.h"
#import "FDSecureStore.h"
#import "HLNotificationHandler.h"
#import "FDAutolayoutHelper.h"
#import "HLFAQUtil.h"
#import "KonotorAudioRecorder.h"
#import "FDBackgroundTaskManager.h"
#import "HLCSATYesNoPrompt.h"
#import "HLChannelViewController.h"
#import "HLTagManager.h"
#import "HLTags.h"
#import "HLConversationUtil.h"
#import "HLControllerUtils.h"
#import "HLMessagePoller.h"
#import "FCRemoteConfigUtil.h"
#import "HLUser.h"
#import "HLCoreServices.h"

typedef struct {
    BOOL isLoading;
    BOOL isShowingAlert;
    BOOL isFirstWordOnLine;
    BOOL isKeyboardOpen;
    BOOL isModalPresentationPreferred;
} FDMessageControllerFlags;


@interface FDMessageController () <UITableViewDelegate, UITableViewDataSource, HLMessageCellDelegate, HLUserMessageCellDelegate, FDAudioInputDelegate, KonotorDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;
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
@property (nonatomic, strong) NSString* currentRecordingMessageId;
@property (nonatomic, strong) NSMutableDictionary* messageHeightMap;
@property (nonatomic, strong) NSMutableDictionary* messageWidthMap;
@property (nonatomic, assign) FDMessageControllerFlags flags;
@property (strong, nonatomic) NSString *appAudioCategory;
@property (nonatomic,strong) NSNumber *channelID;

@property (nonatomic, strong) HLMessagePoller *messagesPoller;

@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic) NSInteger messageCount;
@property (nonatomic) NSInteger messageCountPrevious;
@property (nonatomic) NSInteger messagesDisplayedCount;
@property (nonatomic) NSInteger loadmoreCount;

@property (strong,nonatomic) HLCSATYesNoPrompt *yesNoPrompt;
@property (strong, nonatomic) HLCSATView *CSATView;
@property (nonatomic) BOOL isOneWayChannel;
@property (nonatomic, strong) ConversationOptions *convOptions;
@property (nonatomic) BOOL fromNotification;
@property (nonatomic) BOOL initalLoading;

@property (nonatomic, strong) UILabel *bannerMesagelabel;
@property (nonatomic, strong) UIView *bannerMessageView;
@property (nonatomic, strong) NSArray *viewVerticalConstraints;
@property (nonatomic, strong) NSDictionary *views;
@property (nonatomic, strong) UIView *titleView;
@property (nonatomic, strong) UILabel *channelName;
@property (nonatomic, strong) UILabel *typicalReply;
@property (nonatomic) NSInteger titleWidth;
@property (nonatomic) NSInteger titleHeight;


@end

@implementation FDMessageController

#define INPUT_TOOLBAR_HEIGHT  43
#define TABLE_VIEW_TOP_OFFSET 10
#define CELL_HORIZONTAL_PADDING 4
#define YES_NO_PROMPT_HEIGHT 80
#define KONOTOR_REFRESHINDICATOR_TAG 80
#define KONOTOR_MESSAGESPERPAGE 25

-(instancetype)initWithChannelID:(NSNumber *)channelID andPresentModally:(BOOL)isModal{
    self = [super init];
    return [self initWithChannelID:channelID andPresentModally:isModal fromNotification:NO];
}

-(instancetype)initWithChannelID:(NSNumber *)channelID andPresentModally:(BOOL)isModal fromNotification:(BOOL) fromNotification {
    self = [super init];
    if (self) {
        self.fromNotification = fromNotification;
        self.messageHeightMap = [[NSMutableDictionary alloc]init];
        self.messageWidthMap = [[NSMutableDictionary alloc]init];
        self.initalLoading = true;
        _flags.isFirstWordOnLine = YES;
        _flags.isModalPresentationPreferred = isModal;

        self.messageCount = 0;
        self.messageCountPrevious = 0;
        self.messagesDisplayedCount=20;
        self.loadmoreCount=20;
        self.channelID = channelID;        
        self.channel = [HLChannel getWithID:channelID inContext:[KonotorDataManager sharedInstance].mainObjectContext];
        self.imageInput = [[KonotorImageInput alloc]initWithConversation:self.conversation onChannel:self.channel];
        self.messagesPoller = [[HLMessagePoller alloc] initWithPollType:OnscreenPollFetch];
        [Konotor setDelegate:self];
    }
    return self;
}

-(void) setConversationOptions:(ConversationOptions *)options{
    self.convOptions = options;
}

-(KonotorConversation *)conversation{
    if(!_conversation){
        _conversation = [_channel primaryConversation];
    }
    return _conversation;
}

-(BOOL)isModal{
    return  _flags.isModalPresentationPreferred;
}

-(void)willMoveToParentViewController:(UIViewController *)parent{
    parent.navigationItem.title = self.channel.name;
    self.messagesDisplayedCount = 20;
    self.initalLoading = true;
    self.view.backgroundColor = [UIColor whiteColor];
    [self setSubviews];
    [self updateMessages];
    [self setNavigationItem];
    [self setNavigationTitle:parent];
    [self scrollTableViewToLastCell];
    [self.tableView setHidden:true];
    [HLMessageServices fetchChannelsAndMessagesWithFetchType:ScreenLaunchFetch source:ChatScreen andHandler:nil];
    [Message markAllMessagesAsReadForChannel:self.channel];
    [self prepareInputToolbar];
}

-(void) setNavigationTitle:(UIViewController *)parent {
    
    UIBarButtonItem *left = parent.navigationItem.leftBarButtonItem;
    UIView *view = [left valueForKey:@"view"];
    UIImage *image = [left valueForKey:@"image"];
    CGFloat leftBarButtonWidth = 0.0;
    if(view){
        leftBarButtonWidth=[view frame].size.width;
    }
    
    if(image) {
        leftBarButtonWidth= 30;
    }
    
    self.titleWidth = parent.navigationController.navigationBar.frame.size.width - (3 * leftBarButtonWidth);
    self.titleHeight = parent.navigationController.navigationBar.frame.size.height;
    
    self.titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.titleWidth, self.titleHeight)];
    self.channelName = [[UILabel alloc] initWithFrame:CGRectMake(0, 2, self.titleWidth, self.titleHeight - 2)];
    self.typicalReply = [[UILabel alloc] initWithFrame:CGRectMake(0, self.titleHeight - self.titleHeight/3 - 2, self.titleWidth, 0)];
    self.typicalReply.alpha = 0;
    self.channelName.textAlignment = UITextAlignmentCenter;
    self.channelName.font = [[HLTheme sharedInstance] conversationOverlayTextFont];
    self.channelName.font = [self.channelName.font fontWithSize:18];
    self.channelName.text = self.channel.name;
    [self.titleView addSubview:self.channelName];
    
    self.typicalReply.font = [[HLTheme sharedInstance] conversationOverlayTextFont];
    self.typicalReply.font = [self.typicalReply.font fontWithSize:12];
    self.typicalReply.textAlignment = UITextAlignmentCenter;
    [self.titleView addSubview:self.typicalReply];
    
    parent.navigationItem.titleView = self.titleView;
}

-(void) showTypicalReply:(NSInteger) time {
    self.typicalReply.text = [FDUtilities typicalRepliesMsgForTime:time];
    [UIView animateWithDuration:0.5 animations:^{
        self.channelName.frame = CGRectMake(0, 2, self.titleWidth, self.titleHeight - self.titleHeight/3 - 4);
        self.typicalReply.frame = CGRectMake(0, self.titleHeight - self.titleHeight/3 - 2, self.titleWidth, self.titleHeight/3);
        self.typicalReply.alpha = 1;
    }];
}

-(void) hideTypicalReply {
    [UIView animateWithDuration:0.5 animations:^{
        self.channelName.frame = CGRectMake(0, 2, self.titleWidth, self.titleHeight - 2);
        self.typicalReply.frame = CGRectMake(0, self.titleHeight - self.titleHeight/3 - 2, self.titleWidth, 0);
        self.typicalReply.alpha = 1;
    }];
}

-(void)prepareInputToolbar{
    [self setHeightForTextView:self.inputToolbar.textView];
    [self.inputToolbar prepareView];
}

-(UIView *)tableHeaderView{
    UIView *headerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.height, TABLE_VIEW_TOP_OFFSET)];
    headerView.backgroundColor = self.tableView.backgroundColor;
    return headerView;
}

- (void)tableViewTapped:(UITapGestureRecognizer *)tapObj {
    CGPoint touchLoc = [tapObj locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchLoc];
    if (indexPath.row < self.messages.count) {
        MessageData *message = self.messages[(self.messageCount - self.messagesDisplayedCount)+indexPath.row];
        BOOL isAgentMessage = [Konotor isCurrentUser:[message messageUserType]]?NO:YES; //Changed
        if(isAgentMessage) {
            HLAgentMessageCell *messageCell = [self.tableView cellForRowAtIndexPath:indexPath];
            if ( messageCell ) {
                touchLoc = [self.tableView convertPoint:touchLoc toView:messageCell]; //Convert the touch point with respective tableview cell
                if (! CGRectContainsPoint(messageCell.chatBubbleImageView.frame,touchLoc) && ! CGRectContainsPoint(messageCell.profileImageView.frame,touchLoc)) {
                    [self dismissKeyboard];
                }
            }
            else  {
                [self dismissKeyboard];
            }
        } else {
            HLUserMessageCell *messageCell = [self.tableView cellForRowAtIndexPath:indexPath];
            if ( messageCell ) {
                touchLoc = [self.tableView convertPoint:touchLoc toView:messageCell]; //Convert the touch point with respective tableview cell
                if (! CGRectContainsPoint(messageCell.chatBubbleImageView.frame,touchLoc) && ! CGRectContainsPoint(messageCell.profileImageView.frame,touchLoc)) {
                    [self dismissKeyboard];
                }
            }
            else  {
                [self dismissKeyboard];
            }
        }
        
    }
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self localNotificationSubscription];
    self.tableView.tableHeaderView = [self tableHeaderView];
    [HotlineAppState sharedInstance].currentVisibleChannel = self.channel;
    [self processPendingCSAT];    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self registerAppAudioCategory];
    [self checkChannel:^(BOOL isChannelValid){
        if(isChannelValid) {
            if(!self.channel.managedObjectContext) {
                [self rebuildMessages];
            }
            [self refreshView];
        }
    }];
    [self.messagesPoller begin];
    if([FDUtilities canMakeTypicallyRepliesCall]){
        [self fetchTypicalRepliesIn];
    }
    else{
        //[self showTypicalReply:];
        //save typically replies time here
    }
}

-(void)fetchTypicalRepliesIn{
    [HLCoreServices fetchTypicalReply:^(FDResponseInfo *responseInfo, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!error) {
                NSDictionary* channelsInfo = responseInfo.responseAsDictionary;
                if(channelsInfo[@"channelResponseTime"] != nil) {
                    NSArray *convArr = channelsInfo[@"channelResponseTime"];
                    for (int i = 0; i < [convArr count]; i++) {
                        NSDictionary* item = [convArr objectAtIndex:i];
                        if ([item[@"channelId"] integerValue] == [self.channel.channelID integerValue]) {
                            [self showTypicalReply:[item[@"responseTime"] integerValue]];
                            break;
                        }
                    }
                }
            } else {
                [self hideTypicalReply];
            }
        });
    }];
}


-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.messagesPoller end];
    
    if([Konotor getCurrentPlayingMessageID]){
        [Konotor StopPlayback];
    }
    //add check if audio recording is enabled or not
    FDSecureStore *secureStore = [FDSecureStore sharedInstance];
    if([secureStore boolValueForKey:HOTLINE_DEFAULTS_VOICE_MESSAGE_ENABLED]){
        [self resetAudioSessionCategory];
        if([Konotor isRecording]){
            [Konotor stopRecording];
        }
    }
    [self handleDismissMessageInputView];
    [HotlineAppState sharedInstance].currentVisibleChannel = nil;
    [self localNotificationUnSubscription];
    
    
    if (self.CSATView.isShowing) {
        FDLog(@"Leaving message screen with active CSAT, Recording YES state");
        [self handleUserEvadedCSAT];
    }
    
}

-(void)registerAppAudioCategory{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    self.appAudioCategory = audioSession.category;
}

-(void)resetAudioSessionCategory{
        [self setAudioCategory:self.appAudioCategory];
}

-(void)setAudioCategory:(NSString *) audioSessionCategory{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *setCategoryError = nil;
    
    if (![audioSession setCategory:audioSessionCategory error:&setCategoryError]) {
        FDLog(@"%s setCategoryError=%@", __PRETTY_FUNCTION__, setCategoryError);
    }
}

- (void) handleDismissMessageInputView{
    if(self.audioMessageInputView.window)
        [self audioMessageInput:self.audioMessageInputView dismissButtonPressed:nil];

}

//TODO: isModal value for embedded controller is wrong. Added (&& !self.embedded) as a quick fix - Arv
// Update it in the next release
-(void)setNavigationItem{
    if(_flags.isModalPresentationPreferred && !self.embedded){
        [HLControllerUtils configureCloseButton:self forTarget:self selector:@selector(closeButtonAction:) title:HLLocalizedString(LOC_MESSAGES_CLOSE_BUTTON_TEXT)];
    }else{
        if (!self.embedded) {
            [self configureBackButton];
        }
    }
}

-(UIViewController<UIGestureRecognizerDelegate> *)gestureDelegate{
    return self;
}

-(void)closeButtonAction:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(UIView *)headerView{
    float headerViewWidth      = self.view.frame.size.width;
    float headerViewHeight     = 25;
    CGRect headerViewFrame     = CGRectMake(0, 0, headerViewWidth, headerViewHeight);
    UIView *headerView = [[UIView alloc]initWithFrame:headerViewFrame];
    headerView.backgroundColor = [UIColor clearColor];
    return headerView;
}



-(void)setSubviews{
    FDSecureStore *secureStore = [FDSecureStore sharedInstance];
    NSString *overlayText = [secureStore objectForKey:HOTLINE_DEFAULTS_CONVERSATION_BANNER_MESSAGE];
    
    self.bannerMessageView = [UIView new];
    self.bannerMessageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.bannerMessageView.backgroundColor = [[HLTheme sharedInstance] conversationOverlayBackgroundColor];
    [self.view addSubview:self.bannerMessageView];

    self.bannerMesagelabel = [[UILabel alloc] init];
    self.bannerMesagelabel.font = [[HLTheme sharedInstance] conversationOverlayTextFont];
    self.bannerMesagelabel.text = overlayText;
    self.bannerMesagelabel.numberOfLines = 3;
    self.bannerMesagelabel.textColor = [[HLTheme sharedInstance] conversationOverlayTextColor];
    self.bannerMesagelabel.textAlignment = UITextAlignmentCenter;
    
    self.bannerMesagelabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.bannerMessageView addSubview:self.bannerMesagelabel];
    
    self.tableView = [[UITableView alloc]init];
    self.tableView.backgroundColor = [[HLTheme sharedInstance]messageUIBackgroundColor];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.separatorStyle=UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = 100;
    self.tableView.rowHeight = UITableViewAutomaticDimension;    
    [self.tableView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tableViewTapped:)]];
    [self.view addSubview:self.tableView];
    
    //Bottomview
    self.bottomView = [[UIView alloc]init];
    self.bottomView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.bottomView];
    
    //LoadingActivityIndicator
    self.loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.loadingView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.loadingView startAnimating];
    [self.view addSubview:self.loadingView];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[loadingView]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:@{@"loadingView":self.loadingView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[loadingView]-|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:@{@"loadingView":self.loadingView}]];
    
    
    self.bottomViewHeightConstraint = [FDAutolayoutHelper setHeight:0 forView:self.bottomView inView:self.view];
    self.bottomViewBottomConstraint = [FDAutolayoutHelper bottomAlign:self.bottomView toView:self.view];
    
    self.yesNoPrompt = [[HLCSATYesNoPrompt alloc]initWithDelegate:self andKey:LOC_CSAT_PROMPT_PARTIAL];
    self.yesNoPrompt.translatesAutoresizingMaskIntoConstraints = NO;

     self.views = @{@"tableView" : self.tableView,
                    @"bottomView" : self.bottomView,
                    @"messageOverlayView": self.bannerMessageView,
                    @"overlayText" : self.bannerMesagelabel};
    
    [self.bannerMessageView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[overlayText]|" options:0 metrics:nil views:self.views]];
    [self.bannerMessageView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[overlayText]-5-|" options:0 metrics:nil views:self.views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[messageOverlayView]|" options:0 metrics:nil views:self.views]];
    
    [self setViewVerticalConstraint:overlayText];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bottomView]|" options:0 metrics:nil views:self.views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:nil views:self.views]];
    
    if([self.channel.type isEqualToString:CHANNEL_TYPE_BOTH]){
        
        self.inputToolbar = [[FDInputToolbarView alloc]initWithDelegate:self];
        self.inputToolbar.translatesAutoresizingMaskIntoConstraints = NO;
        [self.inputToolbar showAttachButton:YES];
        
        self.audioMessageInputView = [[FDAudioMessageInputView alloc] initWithDelegate:self];
        self.audioMessageInputView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self updateBottomViewWith:self.inputToolbar andHeight:INPUT_TOOLBAR_HEIGHT];
    }
    
    if([self.channel.type isEqualToString:CHANNEL_TYPE_AGENT_ONLY]){
        self.isOneWayChannel = YES;
    }
}

- (float)lineCountForLabel:(UILabel *)label {
    CGSize maximumLabelSize = CGSizeMake(self.view.frame.size.width-10,9999);
    CGSize sizeOfText = [label.text boundingRectWithSize:maximumLabelSize
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                            attributes:@{NSFontAttributeName:label.font}
                                               context:nil].size;
    int numberOfLines = sizeOfText.height / label.font.pointSize;
    
    return numberOfLines;
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
    NSString *userCellIdentifier = @"HLUserMessageCell";
    NSString *agentCellIdentifier = @"HLAgentMessageCell";
    HLAgentMessageCell *agentCell;
    HLUserMessageCell *userCell;
    BOOL isAgentMessage = true;
    
    if (indexPath.row < self.messages.count) {
        MessageData *message = self.messages[(self.messageCount - self.messagesDisplayedCount)+indexPath.row];
        isAgentMessage = [Konotor isCurrentUser:[message messageUserType]]?NO:YES; //Changed
        
        if(isAgentMessage) {
            agentCell = [tableView dequeueReusableCellWithIdentifier:agentCellIdentifier];
            if (!agentCell) {
                agentCell = [[HLAgentMessageCell alloc] initWithReuseIdentifier:agentCellIdentifier andDelegate:self];
            }
            agentCell.messageData = message;
            [agentCell drawMessageViewForMessage:message parentView:self.view];
        } else {
            userCell = [tableView dequeueReusableCellWithIdentifier:userCellIdentifier];
            if (!userCell) {
                userCell = [[HLUserMessageCell alloc] initWithReuseIdentifier:userCellIdentifier andDelegate:self];
            }
            userCell.messageData = message;
            [userCell drawMessageViewForMessage:message parentView:self.view];
        }
    }
    
    UITableViewCell* refreshCell = [self showRefreshCellIfRequired:indexPath];
    if(refreshCell!=nil) {
        return refreshCell;
    }
    
    if(isAgentMessage && agentCell) {
        return agentCell;
    } else if (userCell) {
        return userCell;
    }
    
    return [[UITableViewCell alloc]init];
}

-(UITableViewCell *) showRefreshCellIfRequired: (NSIndexPath *)index {
    
    if(index.row == 0 && [[self.tableView indexPathsForVisibleRows] containsObject:index] && self.messagesDisplayedCount < self.messages.count && !self.initalLoading){
        UITableViewCell* cell =[self getRefreshStatusCell];
        NSInteger oldnumber = self.messagesDisplayedCount;
        self.messagesDisplayedCount += self.loadmoreCount;
        if(self.messagesDisplayedCount > self.messageCount){
            self.messagesDisplayedCount = self.messageCount;
        }
        [self performSelector:@selector(refreshView:) withObject:@(oldnumber) afterDelay:0];
        return cell;
    }
    return nil;
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

-(NSString *)getIdentityForMessage:(MessageData *)message{
    return ((message.messageId==nil)?[NSString stringWithFormat:@"%ul",message.createdMillis.intValue]:message.messageId);
}

-(void)inputToolbar:(FDInputToolbarView *)toolbar attachmentButtonPressed:(id)sender{
    [self dismissKeyboard];
    [self.imageInput showInputOptions:self];
}

-(void)inputToolbar:(FDInputToolbarView *)toolbar micButtonPressed:(id)sender{
    
    if(![FCRemoteConfigUtil isActiveInboxAndAccount]){
        return;
    }
    
    if([Konotor getCurrentPlayingMessageID]){
        [Konotor StopPlayback];
    }
    
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                BOOL recording = [KonotorAudioRecorder startRecording];
                if(recording){
                    [self updateBottomViewWith:self.audioMessageInputView andHeight:INPUT_TOOLBAR_HEIGHT];
                }
            }
            else {
                UIAlertView *permissionAlert = [[UIAlertView alloc] initWithTitle:nil message:HLLocalizedString(LOC_AUDIO_RECORDING_PERMISSION_DENIED_TEXT) delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
                [permissionAlert show];
            }
        });
    }];
}

-(void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message{
    UIAlertView *alert=[[UIAlertView alloc] initWithTitle:title message:message delegate:self
                                        cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

-(void)inputToolbar:(FDInputToolbarView *)toolbar sendButtonPressed:(id)sender{
    
    if(![FCRemoteConfigUtil isActiveInboxAndAccount]){
        return;
    }
    
    NSCharacterSet *trimChars = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *toSend = [self.inputToolbar.textView.text stringByTrimmingCharactersInSet:trimChars];
    self.inputToolbar.textView.text = @"";
    if(([toSend isEqualToString:@""]) || ([toSend isEqualToString:HLLocalizedString(LOC_MESSAGE_PLACEHOLDER_TEXT)])){
        [self showAlertWithTitle:HLLocalizedString(LOC_EMPTY_MSG_TITLE) andMessage:HLLocalizedString(LOC_EMPTY_MSG_INFO_TEXT)];
        
    }else{
        
        NSDictionary *textFragmentInfo = [[NSDictionary alloc] initWithObjectsAndKeys:  @1, @"fragmentType",
                                                                                        @"text/html",@"contentType",
                                                                                        toSend,@"content",
                                                                                        @0,@"position",nil];
        
        NSArray *fragmentInfo = [[NSArray alloc] initWithObjects:textFragmentInfo, nil];
        [HLUser setUserMessageInitiated];
        if ([HLUser canRegisterUser]) {
            [HLUser registerUser:^(NSError *error) {
                if (!error) {
                    [Konotor uploadNewMessage:fragmentInfo onConversation:self.conversation onChannel:self.channel];
                }
            }];
        } else {
            [Konotor uploadNewMessage:fragmentInfo onConversation:self.conversation onChannel:self.channel];
        }
        [self checkPushNotificationState];
        [self inputToolbar:toolbar textViewDidChange:toolbar.textView];
    }
    [self refreshView];
    [self.messagesPoller reset];
}

-(void) channelsUpdated
{
    [self checkChannel:nil];
}

-(void) checkChannel : (void(^)(BOOL)) completion
{
    NSManagedObjectContext *ctx = [KonotorDataManager sharedInstance].mainObjectContext;
    [ctx performBlock:^{
        BOOL isChannelValid = NO;
        BOOL hasTags =  [HLConversationUtil hasTags:self.convOptions];
        HLChannel *channelToChk = [HLChannel getWithID:self.channelID inContext:ctx];
        if ( channelToChk && channelToChk.isHidden != 0 ) {
            if(hasTags){ // contains tags .. so check that as well
                if([channelToChk hasAtleastATag:self.convOptions.tags]){
                    isChannelValid = YES;
                }
            }
            else {
                isChannelValid = YES;
            }
        }
        if(!isChannelValid){ // remove this channel from the view
            [self.parentViewController.navigationController popViewControllerAnimated:YES];
            if(completion) {
                completion(isChannelValid);
            }
        }
        else {
            // if channel count changed
            if(completion) {
                completion(isChannelValid);
            }
            if(hasTags){
                [[HLTagManager sharedInstance] getChannelsForTags:self.convOptions.tags inContext:ctx withCompletion:^(NSArray *channels){
                    if(channels && channels.count  > 1 ){
                        [self alterNavigationStack];
                    }
                }];
            }
            else {
                [[KonotorDataManager sharedInstance] fetchAllVisibleChannelsWithCompletion:^(NSArray *channelInfos, NSError *error) {
                    if(!error && channelInfos && channelInfos.count > 1){
                        [self alterNavigationStack];
                    }
                }];
            }
        }
    }];
}

-(void) bannerMessageUpdated {
    if (self.bannerMesagelabel != nil) {
        FDSecureStore *secureStore = [FDSecureStore sharedInstance];
        NSString *overlayText = [secureStore objectForKey:HOTLINE_DEFAULTS_CONVERSATION_BANNER_MESSAGE];
        self.bannerMesagelabel.text = overlayText;
        [self.view removeConstraints:self.viewVerticalConstraints];
        [self setViewVerticalConstraint: overlayText];
    }
}

-(void) setViewVerticalConstraint : (NSString *)overlayText {
    float overlayViewHeight = 0.0;
    if (overlayText.length > 0) {
        overlayViewHeight= (MIN([self lineCountForLabel:self.bannerMesagelabel],3.0) *self.bannerMesagelabel.font.pointSize)+15;
    }
    NSDictionary *overlayHeightmetrics = @{@"overlayHeight":[NSNumber numberWithFloat:overlayViewHeight]};
    self.viewVerticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[messageOverlayView(overlayHeight)][tableView][bottomView]" options:0 metrics:overlayHeightmetrics views:self.views];
    [self.view addConstraints:self.viewVerticalConstraints];
}

-(void) alterNavigationStack
{
    if(self.fromNotification) {
        return;
    }
    BOOL containsChannelController = NO;
    for (UIViewController *controller in self.navigationController.viewControllers) {
        if ([controller isMemberOfClass:[HLContainerController class]]) {
            HLContainerController *containerContr = (HLContainerController *)controller;
            if (containerContr.childController && [containerContr.childController isMemberOfClass:[HLChannelViewController class]]) {
                containsChannelController = YES;
            }
        }
    }
    //If channel count changes from 1 to many, alter the navigation stack [channel list controller , current message channel]
    if (!containsChannelController && self.parentViewController) {
        HLChannelViewController *channelController = [[HLChannelViewController alloc]init];
        UIViewController *channelContainer = [[HLContainerController alloc]initWithController:channelController andEmbed:self.embedded];
        [HLConversationUtil setConversationOptions:self.convOptions andViewController:channelController];
        self.parentViewController.navigationController.viewControllers = @[channelContainer,self.parentViewController];
        _flags.isModalPresentationPreferred = NO;
        self.embedded = NO;
        [self setNavigationItem];
    }
}

-(void) rebuildMessages{
    self.channel = [HLChannel getWithID:self.channelID inContext:[KonotorDataManager sharedInstance].mainObjectContext];
    self.conversation = [self.channel primaryConversation];
    self.imageInput = [[KonotorImageInput alloc]initWithConversation:self.conversation onChannel:self.channel];
}

-(void)checkPushNotificationState{
    
    BOOL notificationEnabled = [HLNotificationHandler areNotificationsEnabled];
    
    if (!notificationEnabled) {
        if([Konotor showNotificationDisabledAlert]){
            [self showAlertWithTitle:HLLocalizedString(LOC_MODIFY_PUSH_SETTING_TITLE)
                          andMessage:HLLocalizedString(LOC_MODIFY_PUSH_SETTING_INFO_TEXT)];
        }
    }
}

-(void) askForNotifications{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }else{
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes: (UIRemoteNotificationTypeNewsstandContentAvailability| UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDismissMessageInputView)
                                                 name:HOTLINE_AUDIO_RECORDING_CLOSE object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkReachable)
                                                 name:HOTLINE_NETWORK_REACHABLE object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(channelsUpdated)
                                                name:HOTLINE_CHANNELS_UPDATED object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bannerMessageUpdated)
                                                 name:HOTLINE_BANNER_MESSAGE_UPDATED object:nil];
}

-(void)networkReachable{
    [Message uploadAllUnuploadedMessages];
}

-(void)localNotificationUnSubscription{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HOTLINE_AUDIO_RECORDING_CLOSE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HOTLINE_NETWORK_REACHABLE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HOTLINE_DID_FINISH_PLAYING_AUDIO_MESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HOTLINE_WILL_PLAY_AUDIO_MESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HOTLINE_CHANNELS_UPDATED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HOTLINE_BANNER_MESSAGE_UPDATED object:nil];
}

-(void)handleBecameActive:(NSNotification *)notification{
    [self.messagesPoller begin];
}

-(void)handleEnteredBackground:(NSNotification *)notification{
    [self.messagesPoller end];
}

#pragma mark Keyboard delegate

-(void) keyboardWillShow:(NSNotification *)note{
    NSTimeInterval animationDuration = [[note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    _flags.isKeyboardOpen = YES;
    CGRect keyboardFrame = [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardRect = [self.view convertRect:keyboardFrame fromView:nil];
    CGFloat calculatedHeight = self.view.bounds.size.height - keyboardRect.origin.y;
    CGFloat keyboardCoveredHeight = self.keyboardHeight < calculatedHeight ? calculatedHeight : self.keyboardHeight;
    self.bottomViewBottomConstraint.constant = - keyboardCoveredHeight;
    self.CSATView.CSATPromptCenterYConstraint.constant = -calculatedHeight/2;
    
    self.keyboardHeight = keyboardCoveredHeight;
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self scrollTableViewToLastCell];
    }];
}

-(void) keyboardWillHide:(NSNotification *)note{
    _flags.isKeyboardOpen = NO;
    NSTimeInterval animationDuration = [[note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    self.keyboardHeight = 0.0;
    self.bottomViewBottomConstraint.constant = 0.0;
    self.CSATView.CSATPromptCenterYConstraint.constant = 0;
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}

#pragma mark Text view delegates

-(void)inputToolbar:(FDInputToolbarView *)toolbar textViewDidChange:(UITextView *)textView{
    [self setHeightForTextView:textView];
    [self scrollTableViewToLastCell];
}

-(void)setHeightForTextView:(UITextView *)textView{

    CGFloat NUM_OF_LINES = 5;
    
    CGFloat MAX_HEIGHT = textView.font.lineHeight * NUM_OF_LINES;
    
    CGFloat preferredTextViewHeight = 0;
    
    CGFloat messageHeight = [textView sizeThatFits:CGSizeMake(textView.frame.size.width, CGFLOAT_MAX)].height;
    
    if(messageHeight > MAX_HEIGHT){
        preferredTextViewHeight = MAX_HEIGHT;
        textView.scrollEnabled=YES;
    }
    else{
        preferredTextViewHeight = messageHeight;
        textView.scrollEnabled=NO;
    }
    
    self.bottomViewHeightConstraint.constant = preferredTextViewHeight + 10;
    self.bottomViewBottomConstraint.constant = - self.keyboardHeight;
    
    textView.frame=CGRectMake(textView.frame.origin.x, textView.frame.origin.y, textView.frame.size.width, preferredTextViewHeight);
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
        _flags.isLoading = NO;
        [self refreshView];
        [self.messagesPoller reset];
    }
    [self processPendingCSAT];
}

- (void) didNotifyServerError {
    if(!_flags.isShowingAlert){
        [self showAlertWithTitle:HLLocalizedString(LOC_MESSAGE_UNSENT_TITLE)
                      andMessage:HLLocalizedString(LOC_SERVER_ERROR_INFO_TEXT)];
        _flags.isShowingAlert = YES;
    }
}

- (void) didFinishUploading:(NSString *)messageID{
    [self refreshView];
    [self processPendingCSAT];
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
    
    if([alertView.title isEqualToString:HLLocalizedString(LOC_AUDIO_SIZE_LONG_ALERT_TITLE)]){
        if(buttonIndex == 1){
            [self sendMessage];
        }
    }
    if([alertView.title isEqualToString:HLLocalizedString(LOC_MODIFY_PUSH_SETTING_TITLE)]){
        //TODO: Handle this better. Checking for title looks bad
        [Konotor setDisabledNotificationAlertShown:YES];
        [self askForNotifications];
    }
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
    [Message markAllMessagesAsReadForChannel:self.channel];
    if(obj==nil)
        [self scrollTableViewToLastCell];
    else{
        [self scrollTableViewToCell:((NSNumber*)obj).intValue];
    }
    if(self.initalLoading) {
        [self.loadingView stopAnimating];
        [self.tableView setHidden:false];
        self.initalLoading = false;
    }
}

-(NSArray *)fetchMessages{
    NSSortDescriptor* desc=[[NSSortDescriptor alloc] initWithKey:@"createdMillis" ascending:YES];
    NSMutableArray *messages = [NSMutableArray arrayWithArray:[[Message getAllMesssageForChannel:self.channel] sortedArrayUsingDescriptors:@[desc]]];
    MessageData *firstMessage = messages.firstObject;
    if (firstMessage.isWelcomeMessage && (firstMessage.fragments.count > 0) ) {
        Fragment *lastfragment  = firstMessage.fragments.lastObject;
        if(lastfragment && !lastfragment.content.length) {
            [messages removeObject:firstMessage];
        }
    }
    return messages;
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

-(void)agentCellPerfomAction:(FragmentData *)fragment {
    NSNumber *fragmentType = @([fragment.type intValue]);
    if ([fragmentType isEqualToValue:@2]) {
        FDImagePreviewController *imageController = [[FDImagePreviewController alloc]initWithImage:[UIImage imageWithData:fragment.binaryData1]];
        [imageController presentOnController:self];
    } else if ([fragmentType isEqualToValue:@5]) {
        NSURL *url = [[NSURL alloc]initWithString:fragment.content];
        NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];        
        NSNumber *articleID = [[NSNumber alloc] initWithInt:-1];
        for (NSURLQueryItem *queryItem in [urlComponents queryItems]) {
            if (queryItem.value == nil) {
                continue;
            }
            if ([queryItem.name isEqualToString:@"article_id"]) {
                articleID = [[NSNumber alloc] initWithInteger:[queryItem.value integerValue]];
                break;
            }
        }
        
        if(articleID.integerValue != -1) {
            @try{
                FAQOptions *option = [FAQOptions new];
                if([HLConversationUtil hasTags:self.convOptions]){
                    [option filterContactUsByTags:self.convOptions.tags withTitle:self.convOptions.filteredViewTitle];
                }
                [HLFAQUtil launchArticleID:articleID withNavigationCtlr:self.navigationController andFaqOptions:option]; // Question - The developer will have no controller over the behaviour
            }
            @catch(NSException* e){
                ALog(@"%@",e);
            }
        }
        else {
            @try{
                NSURL * actionUrl=[NSURL URLWithString:fragment.content];
                if([[UIApplication sharedApplication] canOpenURL:actionUrl]){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[UIApplication sharedApplication] openURL:actionUrl];
                    });
                }
            }
            @catch(NSException* e){
                ALog(@"%@",e);
            }
        }
    }
}

-(void)userCellPerfomAction:(FragmentData *)fragment {
    NSNumber *fragmentType = @([fragment.type intValue]);
    if ([fragmentType isEqualToValue:@2]) {
        FDImagePreviewController *imageController = [[FDImagePreviewController alloc]initWithImage:[UIImage imageWithData:fragment.binaryData1]];
        [imageController presentOnController:self];
    }
}

//TODO: Needs refractor
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
        
        [self updateBottomViewWith:self.inputToolbar andHeight:INPUT_TOOLBAR_HEIGHT];
        float audioMsgDuration = 0.0f;
        //[[[Message retriveMessageForMessageId:self.currentRecordingMessageId] durationInSecs] floatValue];
        
        if(audioMsgDuration <= 1){
            
            UIAlertView *shortMessageAlert = [[UIAlertView alloc] initWithTitle:HLLocalizedString(LOC_AUDIO_SIZE_SHORT_ALERT_TITLE) message:HLLocalizedString(LOC_AUDIO_SIZE_SHORT_ALERT_DESCRIPTION) delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [shortMessageAlert show];
            return;
        }
        
        else if(audioMsgDuration > 120){
            
            UIAlertView *longMessageAlert = [[UIAlertView alloc] initWithTitle:HLLocalizedString(LOC_AUDIO_SIZE_LONG_ALERT_TITLE) message:HLLocalizedString(LOC_AUDIO_SIZE_LONG_ALERT_DESCRIPTION) delegate:self cancelButtonTitle:@"No" otherButtonTitles:HLLocalizedString(LOC_AUDIO_SIZE_LONG_ALERT_POST_BUTTON_TITLE), nil];
            [longMessageAlert show];
        }
        else{
            [self sendMessage];
        }
    }
}

- (void) sendMessage{
    [Konotor uploadVoiceRecordingWithMessageID:self.currentRecordingMessageId toConversationID:([self.conversation conversationAlias]) onChannel:self.channel];
    [Konotor cancelRecording];
}

-(HLCsat *)getCSATObject{
    return self.conversation.hasCsat.allObjects.firstObject;
}

-(void)processPendingCSAT{
    
    if ([self.inputToolbar containsUserInputText] || [KonotorAudioRecorder isRecording]){
        FDLog(@"Not showing CSAT prompt, User is currently engaging input toolbar");
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.conversation isCSATResponsePending] && !self.CSATView.isShowing) {
            [self updateBottomViewWith:self.yesNoPrompt andHeight:YES_NO_PROMPT_HEIGHT];
            [self.view layoutIfNeeded];
            [self scrollTableViewToLastCell];
        }
    });
}

-(void)displayCSATPromptWithState:(BOOL)isResolved{
    //Dispose old prompt
    if (self.CSATView) {
        [self.CSATView removeFromSuperview];
        self.CSATView = nil;
    }
    
    HLCsat *csat = self.conversation.hasCsat.allObjects.firstObject;
    BOOL hideFeedBackView = !csat.mobileUserCommentsAllowed.boolValue;
    
    if (isResolved) {
        self.CSATView = [[HLCSATView alloc]initWithController:self hideFeedbackView:hideFeedBackView isResolved:YES];
        self.CSATView.surveyTitle.text = csat.question;
    }else{
        self.CSATView = [[HLCSATView alloc]initWithController:self hideFeedbackView:NO isResolved:NO];
        self.CSATView.surveyTitle.text = HLLocalizedString(LOC_CUST_SAT_NOT_RESOLVED_PROMPT);
    }
    
    self.CSATView.delegate = self;
    [self.CSATView show];
}

-(void)yesButtonClicked:(id)sender{
    [self displayCSATPromptWithState:YES];
    [self updateBottomViewAfterCSATSubmisssion];
}

-(void)noButtonClicked:(id)sender{
    [self displayCSATPromptWithState:NO];
    [self updateBottomViewAfterCSATSubmisssion];
}

-(void)updateBottomViewAfterCSATSubmisssion{
    if (!self.isOneWayChannel) {
        [self updateBottomViewWith:self.inputToolbar andHeight:INPUT_TOOLBAR_HEIGHT];
    }else{
        [self cleanupBottomView];
    }
}

-(void)cleanupBottomView{
    [[self.bottomView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.bottomViewHeightConstraint.constant = 0;
}

-(void)handleUserEvadedCSAT{
    HLCsatHolder *csatHolder = [[HLCsatHolder alloc]init];
    csatHolder.isIssueResolved = self.CSATView.isResolved;
    [self storeAndPostCSAT:csatHolder];
}

-(void)submittedCSAT:(HLCsatHolder *)csatHolder{
    [self storeAndPostCSAT:csatHolder];
}

-(void)storeAndPostCSAT:(HLCsatHolder *)csatHolder{
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].mainObjectContext;
    [context performBlock:^{
        UIBackgroundTaskIdentifier taskID = [[FDBackgroundTaskManager sharedInstance]beginTask];

        HLCsat *csat = [self getCSATObject];
        
        csat.isIssueResolved = csatHolder.isIssueResolved ? @"true" : @"false";
        
        if(csatHolder.userRatingCount > 0){
            csat.userRatingCount = [NSNumber numberWithInt:csatHolder.userRatingCount];
        }else{
            csat.userRatingCount = nil;
        }
        
        if (csatHolder.userComments && csatHolder.userComments.length > 0) {
            csat.userComments = csatHolder.userComments;
        }else{
            csat.userComments = nil;
        }
        
        csat.csatStatus = @(CSAT_RATED);
        
        [context save:nil];
        
        [HLMessageServices postCSATWithID:csat.objectID completion:^(NSError *error) {
            [[FDBackgroundTaskManager sharedInstance]endTask:taskID];
        }];
    }];
}
- (void) dismissKeyboard {
    [self.view endEditing:YES];
}

-(void)dealloc{
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.inputToolbar.delegate = nil;
    self.audioMessageInputView.delegate = nil;
    [self localNotificationUnSubscription];
}

@end
