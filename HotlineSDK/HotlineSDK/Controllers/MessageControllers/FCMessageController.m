//
//  FDMessageController.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 27/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "FCMessageController.h"
#import "FCAgentMessageCell.h"
#import "FCUserMessageCell.h"
#import "FCImageInput.h"
#import "FreshchatSDK.h"
#import "FCMessageUtil.h"
#import "FCMessages.h"
#import "FCMessageHelper.h"
#import "FCMacros.h"
#import "FCLocalNotification.h"
#import "FCAudioMessageInputView.h"
#import "FCInterstitialViewController.h"
#import "FCConstants.h"
#import "FCArticles.h"
#import "FCArticlesController.h"
#import "FCContainerController.h"
#import "FCLocalization.h"
#import "FCTheme.h"
#import "FCUtilities.h"
#import "FCImagePreviewController.h"
#import "FCMessageServices.h"
#import "HotlineAppState.h"
#import "FCBarButtonItem.h"
#import "FCSecureStore.h"
#import "FCNotificationHandler.h"
#import "FCAutolayoutHelper.h"
#import "FCFAQUtil.h"
#import "FCAudioRecorder.h"
#import "FCBackgroundTaskManager.h"
#import "FCCSATYesNoPrompt.h"
#import "FCChannelViewController.h"
#import "FCTagManager.h"
#import "FCTags.h"
#import "FCConversationUtil.h"
#import "FCControllerUtils.h"
#import "FCMessagePoller.h"
#import "FCRemoteConfig.h"
#import "FCUserUtil.h"
#import "FCCoreServices.h"
#import "FCCSATUtil.h"

typedef struct {
    BOOL isLoading;
    BOOL isShowingAlert;
    BOOL isFirstWordOnLine;
    BOOL isKeyboardOpen;
    BOOL isModalPresentationPreferred;
} FDMessageControllerFlags;


@interface FCMessageController () <UITableViewDelegate, UITableViewDataSource, HLMessageCellDelegate, HLMessageCellDelegate, FDAudioInputDelegate, KonotorDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;
@property (nonatomic, strong) NSArray *messages;
@property (nonatomic, strong) FCChannels *channel;
@property (nonatomic, strong) FCInputToolbarView *inputToolbar;
@property (nonatomic, strong) FCAudioMessageInputView *audioMessageInputView;
@property (nonatomic, strong) NSLayoutConstraint *bottomViewHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *bottomViewBottomConstraint;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UIImage *sentImage;
@property (nonatomic, strong) FCConversations *conversation;
@property (nonatomic, strong) FCImageInput *imageInput;
@property (nonatomic, strong) NSString* currentRecordingMessageId;
@property (nonatomic, strong) NSMutableDictionary* messageHeightMap;
@property (nonatomic, strong) NSMutableDictionary* messageWidthMap;
@property (nonatomic, assign) FDMessageControllerFlags flags;
@property (strong, nonatomic) NSString *appAudioCategory;
@property (nonatomic,strong) NSNumber *channelID;

@property (nonatomic, strong) FCMessagePoller *messagesPoller;

@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic) NSInteger messageCount;
@property (nonatomic) NSInteger messageCountPrevious;
@property (nonatomic) NSInteger messagesDisplayedCount;
@property (nonatomic) NSInteger loadmoreCount;

@property (strong,nonatomic) FCCSATYesNoPrompt *yesNoPrompt;
@property (strong, nonatomic) FCCSATView *CSATView;
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

@implementation FCMessageController

#define INPUT_TOOLBAR_HEIGHT  43
#define TABLE_VIEW_TOP_OFFSET 10
#define CELL_HORIZONTAL_PADDING 4
#define YES_NO_PROMPT_HEIGHT 80
#define KONOTOR_REFRESHINDICATOR_TAG 80
#define KONOTOR_MESSAGESPERPAGE 25
#define FRESHCHAT_MESSAGE_BOTTOM_PADDING 10

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
        self.channel = [FCChannels getWithID:channelID inContext:[FCDataManager sharedInstance].mainObjectContext];
        self.imageInput = [[FCImageInput alloc]initWithConversation:self.conversation onChannel:self.channel];
        self.messagesPoller = [[FCMessagePoller alloc] initWithPollType:OnscreenPollFetch];
        [FCMessageHelper setDelegate:self];
    }
    return self;
}

-(void) setConversationOptions:(ConversationOptions *)options{
    self.convOptions = options;
}

-(FCConversations *)conversation{
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
    [self setBackgroundForView:self.view];
    [self setSubviews];
    [self updateMessages];
    [self setNavigationItem];
    [self setNavigationTitle:parent];
    [self scrollTableViewToLastCell];
    [self.tableView setHidden:true];
    [FCMessageServices fetchChannelsAndMessagesWithFetchType:ScreenLaunchFetch source:ChatScreen andHandler:nil];
    [FCMessages markAllMessagesAsReadForChannel:self.channel];
    [self prepareInputToolbar];
}

-(void) setNavigationTitle:(UIViewController *)parent {
        
    UIBarButtonItem *left = parent.navigationItem.leftBarButtonItem;
    UIView *view = [left valueForKey:@"view"];
    CGFloat leftBarButtonWidth = 44; //Default image width
    
    if(view) { //If its a text it will take from here
        leftBarButtonWidth=[view frame].size.width;
    }
    
    self.titleWidth = parent.navigationController.navigationBar.frame.size.width - (3 * leftBarButtonWidth) ;
    self.titleHeight = parent.navigationController.navigationBar.frame.size.height;
    
    self.titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.titleWidth, self.titleHeight)];
    self.channelName = [[UILabel alloc] initWithFrame:CGRectMake(0, 2, self.titleWidth, self.titleHeight - 2)];
    self.typicalReply = [[UILabel alloc] initWithFrame:CGRectMake(0, self.titleHeight - self.titleHeight/3 - 2, self.titleWidth, 0)];
    self.typicalReply.alpha = 0;
    self.typicalReply.clipsToBounds = true;
    self.channelName.textAlignment = UITextAlignmentCenter;
    self.channelName.font = [[FCTheme sharedInstance] navigationBarTitleFont];
    self.channelName.textColor = [[FCTheme sharedInstance] navigationBarTitleColor];
    [self.titleView addSubview:self.channelName];
    
    self.typicalReply.font = [[FCTheme sharedInstance] responseTimeExpectationsFontName];
    self.typicalReply.textColor = [[FCTheme sharedInstance] responseTimeExpectationsFontColor];
    self.typicalReply.textAlignment = UITextAlignmentCenter;
    [self.titleView addSubview:self.typicalReply];
    [self updateTitle];
    parent.navigationItem.titleView = self.titleView;
    
}

-(void) updateTitle {
    self.channelName.text = self.channel.name;
}

-(void) setFooterView {
    FCContainerController *containerCntrl = (FCContainerController *) self.parentViewController;
    if(containerCntrl != nil) {
       [containerCntrl.footerView setViewColor: [[FCTheme sharedInstance] inputToolbarBackgroundColor]];
    }
}

-(void) showReplyResponseTime:(NSInteger) time withType :(enum ResponseTimeType) type {
    self.typicalReply.text = [FCUtilities getReplyResponseForTime:time andType:type];
    
    [UIView animateWithDuration:0.5 animations:^{
        self.channelName.frame = CGRectMake(0, 2, self.titleWidth, self.titleHeight - self.titleHeight/3 - 4);
        self.typicalReply.frame = CGRectMake(0, self.titleHeight - self.titleHeight/3 - 4, self.titleWidth, self.titleHeight/3);
        self.typicalReply.alpha = 1;
    }];
}

-(void) hideReplyResponseTime {
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
        FCMessageData *message = self.messages[(self.messageCount - self.messagesDisplayedCount)+indexPath.row];
        BOOL isAgentMessage = [FCMessageHelper isCurrentUser:[message messageUserType]]?NO:YES; //Changed
        if(isAgentMessage) {
            FCAgentMessageCell *messageCell = [self.tableView cellForRowAtIndexPath:indexPath];
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
            FCUserMessageCell *messageCell = [self.tableView cellForRowAtIndexPath:indexPath];
            if ( messageCell ) {
                touchLoc = [self.tableView convertPoint:touchLoc toView:messageCell]; //Convert the touch point with respective tableview cell
                if (! CGRectContainsPoint(messageCell.chatBubbleImageView.frame,touchLoc)) {
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
    [FCCSATUtil deleteExpiredCSAT];
    [self localNotificationSubscription];
    [self setFooterView];
    self.tableView.tableHeaderView = [self tableHeaderView];
    [self processPendingCSAT];
    [self checkRestoreStateChanged];
    [self.inputToolbar setSendButtonEnabled: [FCStringUtil isNotEmptyString:self.inputToolbar.textView.text]];
}

//TODO:checkRestoreStateChanged is duplicated in HLChannelViewController HLInterstitialViewController ~Sanjith

-(void) checkRestoreStateChanged {
    if([FreshchatUser sharedInstance].isRestoring) {
        FCInterstitialViewController *interstitialController = [[FCInterstitialViewController alloc] initViewControllerWithOptions:self.convOptions andIsEmbed:self.tabBarController != nil ? true : false];
        [FCUtilities resetNavigationStackWithController:interstitialController currentController:self];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self registerAppAudioCategory];
    [self checkChannel];
    [HotlineAppState sharedInstance].currentVisibleChannel = self.channel;
    [self.messagesPoller begin];
    if([FCUtilities canMakeTypicallyRepliesCall] ){
        [self fetchReplyResonseTime];
    } else {
        [self updateReplyResponseTime];
    }
}

-(void) updateReplyResponseTime {
    NSDictionary *currentlyReplyDict = [FCUserDefaults getDictionary:FRESHCHAT_RESPONSE_TIME_EXPECTATION_VALUE];
    NSDictionary *avgReplyDict = [FCUserDefaults getDictionary:FRESHCHAT_RESPONSE_TIME_7_DAYS_VALUE];
    if (currentlyReplyDict != nil) {
        NSNumber *currentChannelTime = currentlyReplyDict[self.channel.channelID];
        if (currentChannelTime != nil) {
            [self showReplyResponseTime:[currentChannelTime integerValue] withType:CURRENT_AVG];
        }
    }
    else if (avgReplyDict != nil) {
        NSNumber *currentChannelTime = avgReplyDict[self.channel.channelID];
        if (currentChannelTime != nil) {
            [self showReplyResponseTime:[currentChannelTime integerValue] withType:LAST_WEEK_AVG];
        }
    }
}

-(void)fetchReplyResonseTime{
    [FCCoreServices fetchTypicalReply:^(FCResponseInfo *responseInfo, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!error) {
                [FCUserDefaults setObject:[NSDate date] forKey:CONFIG_RC_LAST_RESPONSE_TIME_EXPECTATION_FETCH_INTERVAL];
                NSDictionary* channelsInfo = responseInfo.responseAsDictionary;
                if(!([channelsInfo[@"channelResponseTime"] count] == 0)) { //If the array is nil, it will be 0 as well, as nil maps to 0; therefore checking whether the array exists is unnecessary
                    [FCUserDefaults setDictionary:[self getChannelReplyTimeForResponse:channelsInfo[@"channelResponseTime"]] forKey:FRESHCHAT_RESPONSE_TIME_EXPECTATION_VALUE];
                    
                }
                if(!([channelsInfo[@"channelResponseTimesFor7Days"] count] == 0)) {
                    [FCUserDefaults setDictionary:[self getChannelReplyTimeForResponse:channelsInfo[@"channelResponseTimesFor7Days"]] forKey:FRESHCHAT_RESPONSE_TIME_7_DAYS_VALUE];
                }
                [self updateReplyResponseTime];
            } else {
                [self hideReplyResponseTime];
            }
        });
    }];
}

- (NSMutableDictionary *) getChannelReplyTimeForResponse : (NSArray *)convArr{
    NSMutableDictionary *replyResponseDict = [[NSMutableDictionary alloc]init];
    for (int i = 0; i < [convArr count]; i++) {
        NSDictionary* item = [convArr objectAtIndex:i];
        NSNumber *responseTime = item[@"responseTime"];
        NSNumber *channelId = item[@"channelId"];
        [replyResponseDict setObject:responseTime forKey:channelId];
    }
    return replyResponseDict;
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.messagesPoller end];
    [self.imageInput dismissAttachmentActionSheet];
    if([FCMessageHelper getCurrentPlayingMessageID]){
        [FCMessageHelper StopPlayback];
    }
    //add check if audio recording is enabled or not
    FCSecureStore *secureStore = [FCSecureStore sharedInstance];
    if([secureStore boolValueForKey:HOTLINE_DEFAULTS_VOICE_MESSAGE_ENABLED]){
        [self resetAudioSessionCategory];
        if([FCMessageHelper isRecording]){
            [FCMessageHelper stopRecording];
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
        [FCControllerUtils configureCloseButton:self forTarget:self selector:@selector(closeButtonAction:) title:HLLocalizedString(LOC_MESSAGES_CLOSE_BUTTON_TEXT)];
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
    FCSecureStore *secureStore = [FCSecureStore sharedInstance];
    NSString *overlayText = [secureStore objectForKey:HOTLINE_DEFAULTS_CONVERSATION_BANNER_MESSAGE];
    
    self.bannerMessageView = [UIView new];
    self.bannerMessageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.bannerMessageView.backgroundColor = [[FCTheme sharedInstance] conversationOverlayBackgroundColor];
    [self.view addSubview:self.bannerMessageView];

    self.bannerMesagelabel = [[UILabel alloc] init];
    self.bannerMesagelabel.font = [[FCTheme sharedInstance] conversationOverlayTextFont];
    self.bannerMesagelabel.text = overlayText;
    self.bannerMesagelabel.numberOfLines = 3;
    self.bannerMesagelabel.textColor = [[FCTheme sharedInstance] conversationOverlayTextColor];
    self.bannerMesagelabel.textAlignment = UITextAlignmentCenter;
    
    self.bannerMesagelabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.bannerMessageView addSubview:self.bannerMesagelabel];
    
    self.tableView = [[UITableView alloc]init];
    [self setBackgroundForView:self.tableView];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.separatorStyle=UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = 100;
    [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, FRESHCHAT_MESSAGE_BOTTOM_PADDING, 0)];
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
    self.loadingView.color = [[FCTheme sharedInstance] progressBarColor];
    [self.loadingView startAnimating];
    [self.view addSubview:self.loadingView];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[loadingView]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:@{@"loadingView":self.loadingView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[loadingView]-|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:@{@"loadingView":self.loadingView}]];
    
    
    self.bottomViewHeightConstraint = [FCAutolayoutHelper setHeight:0 forView:self.bottomView inView:self.view];
    self.bottomViewBottomConstraint = [FCAutolayoutHelper bottomAlign:self.bottomView toView:self.view];
    
    self.yesNoPrompt = [[FCCSATYesNoPrompt alloc]initWithDelegate:self andKey:LOC_CSAT_PROMPT_PARTIAL];
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
        
        self.inputToolbar = [[FCInputToolbarView alloc]initWithDelegate:self];
        self.inputToolbar.translatesAutoresizingMaskIntoConstraints = NO;
        [self.inputToolbar showAttachButton:YES];
        
        self.audioMessageInputView = [[FCAudioMessageInputView alloc] initWithDelegate:self];
        self.audioMessageInputView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self updateBottomViewWith:self.inputToolbar andHeight:INPUT_TOOLBAR_HEIGHT];
    }
    
    if([self.channel.type isEqualToString:CHANNEL_TYPE_AGENT_ONLY]){
        self.isOneWayChannel = YES;
    }
}

- (void) setBackgroundForView : (UIView *)view{
    
    id component = [[FCTheme sharedInstance] getMessageDetailBackgroundComponent];
    if([component isKindOfClass:[UIColor class]]){
        view.backgroundColor = component;
    }
    else if([component isKindOfClass:[UIImage class]]){
        [view setBackgroundColor: [[UIColor alloc] initWithPatternImage:component]];
    }
    else{
        [view setBackgroundColor: [UIColor whiteColor]];
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
    FCAgentMessageCell *agentCell;
    FCUserMessageCell *userCell;
    BOOL isAgentMessage = true;
    CGRect screenRect = self.view.bounds;
    if (indexPath.row < self.messages.count) {
        FCMessageData *message = self.messages[(self.messageCount - self.messagesDisplayedCount)+indexPath.row];
        isAgentMessage = [FCMessageHelper isCurrentUser:[message messageUserType]]?NO:YES; //Changed
        
        if(isAgentMessage) {
            agentCell = [tableView dequeueReusableCellWithIdentifier:agentCellIdentifier];
            if (!agentCell) {
                agentCell = [[FCAgentMessageCell alloc] initWithReuseIdentifier:agentCellIdentifier andDelegate:self];
            }
            agentCell.tagVal = indexPath.row;
            agentCell.maxcontentWidth = (NSInteger) screenRect.size.width - ((screenRect.size.width/100)*20);
            agentCell.messageData = message;
            [agentCell drawMessageViewForMessage:message parentView:self.view withTag:indexPath.row];
        } else {
            userCell = [tableView dequeueReusableCellWithIdentifier:userCellIdentifier];
            if (!userCell) {
                userCell = [[FCUserMessageCell alloc] initWithReuseIdentifier:userCellIdentifier andDelegate:self];
            }
            userCell.maxcontentWidth = (NSInteger) screenRect.size.width - ((screenRect.size.width/100)*20);
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

-(NSString *)getIdentityForMessage:(FCMessageData *)message{
    return ((message.messageId==nil)?[NSString stringWithFormat:@"%ul",message.createdMillis.intValue]:message.messageId);
}

-(void)inputToolbar:(FCInputToolbarView *)toolbar attachmentButtonPressed:(id)sender{
    [self dismissKeyboard];
    [self.imageInput showInputOptions:self];
}

-(void)inputToolbar:(FCInputToolbarView *)toolbar micButtonPressed:(id)sender{
    
    if(![[FCRemoteConfig sharedInstance] isActiveInboxAndAccount]){
        return;
    }
    
    if([FCMessageHelper getCurrentPlayingMessageID]){
        [FCMessageHelper StopPlayback];
    }
    
//    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (granted) {
//                BOOL recording = [KonotorAudioRecorder startRecording];
//                if(recording){
//                    [self updateBottomViewWith:self.audioMessageInputView andHeight:INPUT_TOOLBAR_HEIGHT];
//                }
//            }
//            else {
//                UIAlertView *permissionAlert = [[UIAlertView alloc] initWithTitle:nil message:HLLocalizedString(LOC_AUDIO_RECORDING_PERMISSION_DENIED_TEXT) delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
//                [permissionAlert show];
//            }
//        });
//    }];
}

-(void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message{
    UIAlertView *alert=[[UIAlertView alloc] initWithTitle:title message:message delegate:self
                                        cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

-(void)inputToolbar:(FCInputToolbarView *)toolbar sendButtonPressed:(id)sender{
    
    if(![[FCRemoteConfig sharedInstance] isActiveInboxAndAccount]){
        return;
    }
    
    NSCharacterSet *trimChars = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *toSend = [self.inputToolbar.textView.text stringByTrimmingCharactersInSet:trimChars];
    self.inputToolbar.textView.text = @"";
    [self.inputToolbar setSendButtonEnabled:NO];
    [FCMessageHelper uploadMessageWithImage:nil textFeed:toSend onConversation:self.conversation andChannel:self.channel];
    [self checkPushNotificationState];
    [self inputToolbar:toolbar textViewDidChange:toolbar.textView];
    [self refreshView];
    [self.messagesPoller reset];
}

-(void) checkChannel
{
    [self checkChannel:^(BOOL isChannelValid){
        if(isChannelValid) {
            if(!self.channel.managedObjectContext || self.channel.isFault || self.conversation.isFault ) {
                [self updateBottomViewAfterCSATSubmisssion];
                [self rebuildMessages];
            }
            [self updateTitle];
            [self refreshView];
        }
    }];
}

-(void) checkChannel : (void(^)(BOOL)) completion
{
    NSManagedObjectContext *ctx = [FCDataManager sharedInstance].mainObjectContext;
    [ctx performBlock:^{
        BOOL isChannelValid = NO;
        BOOL hasTags =  [FCConversationUtil hasTags:self.convOptions];
        FCChannels *channelToChk = [FCChannels getWithID:self.channelID inContext:ctx];
        if ( channelToChk && ( [channelToChk.isHidden intValue] == 0 || [channelToChk.isDefault intValue] == 1 ) ) {
            if(hasTags){ // contains tags .. so check that as well
                if([channelToChk hasAtleastATag:self.convOptions.tags]){
                    isChannelValid = YES;
                }
            }
            else {
                isChannelValid = YES;
            }
        }
        if(hasTags){
            [[FCTagManager sharedInstance] getChannelsForTags:self.convOptions.tags inContext:ctx withCompletion:^(NSArray *channels, NSError *error) {
                [self processNavStackChanges:channels channelsError:error isValidChannel:isChannelValid];
            }];
        }
        else {
            [[FCDataManager sharedInstance] fetchAllVisibleChannelsWithCompletion:^(NSArray *channelInfos, NSError *error) {
                [self processNavStackChanges:channelInfos channelsError:error isValidChannel:isChannelValid];
            }];
        }
        if(completion) {
            completion(isChannelValid);
        }
    }];
}

-(void) bannerMessageUpdated {
    if (self.bannerMesagelabel != nil) {
        FCSecureStore *secureStore = [FCSecureStore sharedInstance];
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

-(void) processNavStackChanges: (NSArray*)channels channelsError:(NSError *)error isValidChannel:(BOOL)isValidChannel  {
    if (error) {
        return;
    }
    if(!isValidChannel) {
        if(channels && channels.count == 0 ){
            [self alterNavigationStack];
        }
        [self.parentViewController.navigationController popViewControllerAnimated:YES];
    } else {
        if(channels && channels.count > 1) {
            [self alterNavigationStack];
        }
    }
}

-(void) alterNavigationStack
{
    if(self.fromNotification) {
        return;
    }
    BOOL containsChannelController = NO;
    for (UIViewController *controller in self.navigationController.viewControllers) {
        if ([controller isMemberOfClass:[FCContainerController class]]) {
            FCContainerController *containerContr = (FCContainerController *)controller;
            if (containerContr.childController && [containerContr.childController isMemberOfClass:[FCChannelViewController class]]) {
                containsChannelController = YES;
            }
        }
    }
    //If channel count changes from 1 to many, alter the navigation stack [channel list controller , current message channel]
    if (!containsChannelController && self.parentViewController) {
        FCChannelViewController *channelController = [[FCChannelViewController alloc]init];
        UIViewController *channelContainer = [[FCContainerController alloc]initWithController:channelController andEmbed:self.embedded];
        [FCConversationUtil setConversationOptions:self.convOptions andViewController:channelController];
        self.parentViewController.navigationController.viewControllers = @[channelContainer,self.parentViewController];
        _flags.isModalPresentationPreferred = NO;
        self.embedded = NO;
        [self setNavigationItem];
    }
}

-(void) rebuildMessages{
    self.channel = [FCChannels getWithID:self.channelID inContext:[FCDataManager sharedInstance].mainObjectContext];
    self.conversation = [self.channel primaryConversation];
    self.imageInput = [[FCImageInput alloc]initWithConversation:self.conversation onChannel:self.channel];
    [HotlineAppState sharedInstance].currentVisibleChannel = self.channel;    
}

-(void)checkPushNotificationState{

    if(![[FCTheme sharedInstance] shouldShowPushPrompt]) return;
    BOOL notificationEnabled = [FCNotificationHandler areNotificationsEnabled];
    if (!notificationEnabled) {
        [self showNotificationPermissionPrompt];
    }
}

-(void) showNotificationPermissionPrompt{
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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkChannel)
                                                name:HOTLINE_CHANNELS_UPDATED object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bannerMessageUpdated)
                                                 name:HOTLINE_BANNER_MESSAGE_UPDATED object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreStateChanged:)
                                                 name:FRESHCHAT_USER_RESTORE_STATE object:nil];
}

-(void)localNotificationUnSubscription{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HOTLINE_AUDIO_RECORDING_CLOSE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FRESHCHAT_DID_FINISH_PLAYING_AUDIO_MESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FRESHCHAT_WILL_PLAY_AUDIO_MESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HOTLINE_CHANNELS_UPDATED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HOTLINE_BANNER_MESSAGE_UPDATED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FRESHCHAT_USER_RESTORE_STATE object:nil];
}

-(void)restoreStateChanged:(NSNotification *)notification {
    if([notification.userInfo[@"state"] intValue] == 0) {
        [self checkRestoreStateChanged];
    }
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

-(void)inputToolbar:(FCInputToolbarView *)toolbar textViewDidChange:(UITextView *)textView{
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

//Will use when we are start using audio message cc @PrasannanFD
/*
- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    _flags.isShowingAlert = NO;
    
    if([alertView.title isEqualToString:HLLocalizedString(LOC_AUDIO_SIZE_LONG_ALERT_TITLE)]){
        if(buttonIndex == 1){
            [self sendMessage];
        }
    }
}*/

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

- (void) refreshView {
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
    [FCMessages markAllMessagesAsReadForChannel:self.channel];
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
    [self processPendingCSAT];
}

-(NSArray *)fetchMessages{
    NSSortDescriptor* desc=[[NSSortDescriptor alloc] initWithKey:@"createdMillis" ascending:YES];
    NSMutableArray *messages = [NSMutableArray arrayWithArray:[[FCMessages getAllMesssageForChannel:self.channel] sortedArrayUsingDescriptors:@[desc]]];
    FCMessageData *firstMessage = messages.firstObject;
    if (firstMessage.isWelcomeMessage && (firstMessage.fragments.count > 0) ) {
        FCMessageFragments *lastfragment  = firstMessage.fragments.lastObject;
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
    [self setNavigationTitle:self.parentViewController];
    if([FCUtilities canMakeTypicallyRepliesCall] ){
        [self fetchReplyResonseTime];
    } else {
        [self updateReplyResponseTime];
    }
    [self inputToolbar:self.inputToolbar textViewDidChange:self.inputToolbar.textView];
    [self scrollTableViewToLastCell];
}

#pragma mark - Message cell delegates

-(void)performActionOn:(FragmentData *)fragment {
    NSNumber *fragmentType = @([fragment.type intValue]);
    if ([fragmentType isEqualToValue:@2]) {
        FCImagePreviewController *imageController = [[FCImagePreviewController alloc]initWithImage:[UIImage imageWithData:fragment.binaryData1]];
        [imageController presentOnController:self];
    } else if ([fragmentType isEqualToValue:@5]) {
        NSURL *url = [fragment getOpenURL];
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
                if([FCConversationUtil hasTags:self.convOptions]){
                    [option filterContactUsByTags:self.convOptions.tags withTitle:self.convOptions.filteredViewTitle];
                }
                [FCFAQUtil launchArticleID:articleID withNavigationCtlr:self.navigationController andFaqOptions:option]; // Question - The developer will have no controller over the behaviour
            }
            @catch(NSException* e){
                ALog(@"%@",e);
            }
        }
        else {
            @try{
                NSURL *actionUrl = [fragment getOpenURL];
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

-(BOOL)handleLinkDelegate: (NSURL *)url {
    return [FCUtilities handleLink:url faqOptions:nil navigationController:self.navigationController];
}

//TODO: Needs refractor
#pragma mark - Audio toolbar delegates

-(void)audioMessageInput:(FCAudioMessageInputView *)toolbar dismissButtonPressed:(id)sender{
    [FCMessageHelper cancelRecording];
    [self updateBottomViewWith:self.inputToolbar andHeight:INPUT_TOOLBAR_HEIGHT];
}

-(void) audioMessageInput:(FCAudioMessageInputView *)toolbar stopButtonPressed:(id)sender{
    self.currentRecordingMessageId=[FCMessageHelper stopRecording];
}

-(void)audioMessageInput:(FCAudioMessageInputView *)toolbar sendButtonPressed:(id)sender{
    self.currentRecordingMessageId=[FCMessageHelper stopRecordingOnConversation:self.conversation];
    
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
    [FCMessageHelper uploadVoiceRecordingWithMessageID:self.currentRecordingMessageId toConversationID:([self.conversation conversationAlias]) onChannel:self.channel];
    [FCMessageHelper cancelRecording];
}

-(FCCsat *)getCSATObject{
    return self.conversation.hasCsat.allObjects.firstObject;
}

-(void)processPendingCSAT{
    
    if ([FCStringUtil isNotEmptyString:self.inputToolbar.textView.text] || [FCAudioRecorder isRecording]){
        FDLog(@"Not showing CSAT prompt, User is currently engaging input toolbar");
        return;
    }
    FCCsat *csat = [self getCSATObject];
    //Check for CSAT Timeout state
    if([FCCSATUtil isCSATExpiredForInitiatedTime:[csat.initiatedTime longValue]] && [self.conversation isCSATResponsePending]){
        [FCCSATUtil deleteCSATAndUpdateConversation:csat];
    }
    else{
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.conversation isCSATResponsePending] && !self.CSATView.isShowing && self.yesNoPrompt) {
                [self updateBottomViewWith:self.yesNoPrompt andHeight:YES_NO_PROMPT_HEIGHT];
                [self.view layoutIfNeeded];
            }
        });
    }
}

-(void)displayCSATPromptWithState:(BOOL)isResolved{
    //Dispose old prompt
    if (self.CSATView) {
        [self.CSATView removeFromSuperview];
        self.CSATView = nil;
    }
    
    FCCsat *csat = self.conversation.hasCsat.allObjects.firstObject;
    BOOL hideFeedBackView = !csat.mobileUserCommentsAllowed.boolValue;
    
    if (isResolved) {
        self.CSATView = [[FCCSATView alloc]initWithController:self hideFeedbackView:hideFeedBackView isResolved:YES];
        NSString * cSatQues = (trimString([FCUtilities getLocalizedPositiveFeedCSATQues]).length > 0) ? [FCUtilities getLocalizedPositiveFeedCSATQues] : csat.question;
        if([FCUtilities containsHTMLContent:cSatQues]) {
            self.CSATView.surveyTitle.attributedText = [FCUtilities getAttributedContentForString:cSatQues withFont:self.CSATView.surveyTitle.font];
        } else {
            self.CSATView.surveyTitle.text = cSatQues;
        }
    }else{
        self.CSATView = [[FCCSATView alloc]initWithController:self hideFeedbackView:NO isResolved:NO];
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
    NSManagedObjectContext *context = [FCDataManager sharedInstance].mainObjectContext;
    [context performBlock:^{
        UIBackgroundTaskIdentifier taskID = [[FCBackgroundTaskManager sharedInstance]beginTask];

        FCCsat *csat = [self getCSATObject];
        
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
        
        [FCMessageServices postCSATWithID:csat.objectID completion:^(NSError *error) {
            [[FCBackgroundTaskManager sharedInstance]endTask:taskID];
            [FCUtilities postUnreadCountNotification];
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
