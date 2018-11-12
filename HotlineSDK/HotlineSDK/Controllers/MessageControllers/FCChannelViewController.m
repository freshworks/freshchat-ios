//
//  HLChannelViewController.m
//  HotlineSDK
//
//  Created by user on 04/11/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FCChannelViewController.h"
#import "FCMacros.h"
#import "FCTheme.h"
#import "FCLocalNotification.h"
#import "FCContainerController.h"
#import "FCMessageController.h"
#import "FCMessages.h"
#import "FCMessageUtil.h"
#import "FCConversations.h"
#import "FCInterstitialViewController.h"
#import "FCDateUtil.h"
#import "FCUtilities.h"
#import "FCLocalization.h"
#import "FCNotificationBanner.h"
#import "FCBarButtonItem.h"
#import "FCEmptyResultView.h"
#import "FCCell.h"
#import "FCAutolayoutHelper.h"
#import "FCMessageServices.h"
#import "FCIconDownloader.h"
#import "FCReachabilityManager.h"
#import "FCTagManager.h"
#import "FCConversationUtil.h"
#import "FCControllerUtils.h"
#import "FCLoadingViewBehaviour.h"
#import "FCSecureStore.h"
#import "FCCSATUtil.h"
#import "FCJWTAuthValidator.h"
#import "FCJWTUtilities.h"
#import "FCRemoteConfig.h"

@interface FCChannelViewController () <HLLoadingViewBehaviourDelegate,UIAlertViewDelegate>

@property (nonatomic, strong) NSArray *channels;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) FCEmptyResultView *emptyResultView;
@property (nonatomic, strong) FCIconDownloader *iconDownloader;
@property (nonatomic, strong) ConversationOptions *convOptions;
@property (nonatomic, strong) FCTheme *theme;
@property BOOL isFilteredView;
@property (nonatomic, strong) FCLoadingViewBehaviour *loadingViewBehaviour;
@property (nonatomic) BOOL isJWTAlertShown;

@end

@implementation FCChannelViewController

-(void)willMoveToParentViewController:(UIViewController *)parent{
    [super willMoveToParentViewController:parent];
    self.theme = [FCTheme sharedInstance];
    self.tableView.backgroundColor = [self.theme channelListBackgroundColor];
    if([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)])
    {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    FCContainerController * containerCtr =  (FCContainerController*)self.parentViewController;
    [containerCtr.footerView setViewColor:self.tableView.backgroundColor];
    self.navigationController.navigationBar.barTintColor = [self.theme navigationBarBackgroundColor];
    self.navigationController.navigationBar.titleTextAttributes = @{
                                                                    NSForegroundColorAttributeName: [self.theme navigationBarTitleColor],
                                                                    NSFontAttributeName: [self.theme navigationBarTitleFont]
                                                                    };
    self.iconDownloader = [[FCIconDownloader alloc]init];
    [self setNavigationItem];
}

- (void) setConversationOptions:(ConversationOptions *)options{
    self.convOptions = options;
    self.isFilteredView = [FCConversationUtil hasTags:self.convOptions];
}

-(BOOL)canDisplayFooterView{
    return NO;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [FCCSATUtil deleteExpiredCSAT];
    [self.loadingViewBehaviour load:self.channels.count];
    [self loadChannels];
    [self checkRestoreStateChanged];
    if([[FCRemoteConfig sharedInstance] isUserAuthEnabled]){
        [self addJWTObservers];
        [self jwtStateChange];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];    
    [self localNotificationSubscription];
    [self fetchUpdates];
    self.footerView.hidden = YES;
    [self setNavigationItem];
}

-(void)fetchUpdates{
    [[FCDataManager sharedInstance]areChannelsEmpty:^(BOOL isEmpty) {
        enum MessageFetchType type = isEmpty ? FetchAll : ScreenLaunchFetch;
        ShowNetworkActivityIndicator();
        [FCMessageServices fetchChannelsAndMessagesWithFetchType:type
                                                          source:ChatScreen
                                                      andHandler:^(NSError *error) {
           HideNetworkActivityIndicator();
        }];
    }];
}

-(void)loadChannels{
    HideNetworkActivityIndicator();
    NSManagedObjectContext *context = [FCDataManager sharedInstance].mainObjectContext;
    if(self.isFilteredView){
        [[FCTagManager sharedInstance] getChannelsForTags:self.convOptions.tags
                                                    inContext:context
                                               withCompletion:^(NSArray<FCChannels *> *channels, NSError *error){
            
            [self updateChannelWithInfo:channels];
        }];
    }
    else{
        [[FCDataManager sharedInstance] fetchAllVisibleChannelsWithCompletion:^(NSArray *channelInfos, NSError *error) {
            if (!error) {
                [self updateChannelWithInfo:channelInfos];
            }
        }];
    }
 }

- (void) updateChannelWithInfo :(NSArray *) channelInfo{
    if(self.isFilteredView && channelInfo.count == 0 ){
        FCChannels *defaultChannel = [FCChannels getDefaultChannelInContext:[FCDataManager sharedInstance].mainObjectContext];
        if(defaultChannel != nil) {
            channelInfo = @[defaultChannel];
        } else {
            [self.loadingViewBehaviour updateResultsView:NO andCount:channelInfo.count];
            channelInfo = @[];
        }
    }
    if (channelInfo.count == 1) {
        BOOL isEmbedded = (self.tabBarController != nil) ? YES : NO;
        self.navigationController.viewControllers = @[[FCControllerUtils getConvController:isEmbedded
                                                       withOptions:self.convOptions andChannels:channelInfo]];
    }
    else{
        BOOL refreshData = NO;
        
        NSArray *sortedChannel = [self sortChannelList:channelInfo];
        if ( self.channels ) {
            refreshData = YES;
        }
        self.channels = sortedChannel;
        refreshData = refreshData || (self.channels.count > 0);
        if ( ![[FCReachabilityManager sharedInstance] isReachable] || refreshData ) {
            [self.loadingViewBehaviour updateResultsView:NO andCount:channelInfo.count];
        }
        [self.tableView reloadData];
    }
}
 

-(NSArray *)sortChannelList:(NSArray *)channelInfos{
    
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    NSMutableArray *messages = [[NSMutableArray alloc]init];
    
    for(FCChannelInfo *channel in channelInfos){
        FCMessages *lastMessage = [self getLastMessageInChannel:channel.channelID];
        if (lastMessage) {
            [messages addObject:lastMessage];
        }
    }
    
    id sort = [NSSortDescriptor sortDescriptorWithKey:@"createdMillis" ascending:NO];
    id positionSort = [NSSortDescriptor sortDescriptorWithKey:@"belongsToChannel.position" ascending:YES];
    messages = [[messages sortedArrayUsingDescriptors:@[sort,positionSort]] mutableCopy];
    for(FCMessages *message in messages){
        if (message.belongsToChannel) {
            FCChannelInfo *chInfo = [[FCChannelInfo alloc] initWithChannel:message.belongsToChannel];
            [results addObject:chInfo];
        }
    }
    return results;
}

-(void)setNavigationItem{
    UIBarButtonItem *closeButton = [[FCBarButtonItem alloc]initWithTitle:HLLocalizedString(LOC_CHANNELS_CLOSE_BUTTON_TEXT) style:UIBarButtonItemStylePlain target:self action:@selector(closeButton:)];
    self.parentViewController.navigationItem.title = HLLocalizedString(LOC_CHANNELS_TITLE_TEXT);

    if (!self.embedded) {
        self.parentViewController.navigationItem.leftBarButtonItem = closeButton;
        [self.navigationController.interactivePopGestureRecognizer setEnabled:NO];
    }
    else {
        [self configureBackButton];
    }
    if([FCConversationUtil hasFilteredViewTitle:self.convOptions]){
        self.parentViewController.navigationItem.title = self.convOptions.filteredViewTitle;
    }
}

-(void)localNotificationSubscription{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadChannels)
                                                 name:HOTLINE_MESSAGES_DOWNLOADED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadChannels)
                                                 name:HOTLINE_CHANNELS_UPDATED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreStateChanged:)
                                                 name:FRESHCHAT_USER_RESTORE_STATE object:nil];
}

-(void)localNotificationUnSubscription{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HOTLINE_MESSAGES_DOWNLOADED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HOTLINE_CHANNELS_UPDATED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FRESHCHAT_USER_RESTORE_STATE object:nil];
}

-(void)restoreStateChanged:(NSNotification *)notification {
    if([notification.userInfo[@"state"] intValue] == 0) {
        [self checkRestoreStateChanged];
    }
}

-(void) checkRestoreStateChanged {
    if([FreshchatUser sharedInstance].isRestoring) {
        FCInterstitialViewController *interstitialController = [[FCInterstitialViewController alloc] initViewControllerWithOptions:self.convOptions andIsEmbed:self.embedded];
        [FCUtilities resetNavigationStackWithController:interstitialController currentController:self];
        [self localNotificationUnSubscription];
    }
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self localNotificationUnSubscription];
    if([[FCRemoteConfig sharedInstance] isUserAuthEnabled]){
        [self removeJWTObservers];
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"HLChannelsCell";
    
    FCCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[FCCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier isChannelCell:YES];
    }
    
    //Update cell properties
    
    if (indexPath.row < self.channels.count) {
        FCChannelInfo *channel =  self.channels[indexPath.row];
        
        FCMessages *lastMessage = [self getLastMessageInChannel:channel.channelID];
        cell.separatorInset = UIEdgeInsetsZero;
        cell.titleLabel.text  = channel.name;
        
        cell.tag = indexPath.row;
        
        NSDate* date=[NSDate dateWithTimeIntervalSince1970:lastMessage.createdMillis.longLongValue/1000];
        
        if([lastMessage.createdMillis intValue]){
            cell.lastUpdatedLabel.text= [FCDateUtil stringRepresentationForDate:date includeTimeForCurrentYear:NO];
        }
        else{
            cell.lastUpdatedLabel.text = nil;
        }
        
        NSString *fragmentHTML = [lastMessage getDetailDescriptionForMessage];
        NSError *parseErr;
        NSMutableAttributedString *attributedTitleString = [[NSMutableAttributedString alloc] initWithData:[fragmentHTML dataUsingEncoding:NSUnicodeStringEncoding]
                                                                                                   options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
                                                                                        documentAttributes:nil
                                                                                                     error:&parseErr];
        
        if(parseErr) {
            cell.detailLabel.text = fragmentHTML;
        } else {
            cell.detailLabel.text = [attributedTitleString string];
        }
        NSInteger unreadCount = [FCMessages getUnreadMessagesCountForChannel:channel.channelID];
        
        [cell.badgeView updateBadgeCount:unreadCount];
        
        [FCUtilities loadImageAndPlaceholderBgWithUrl:channel.iconURL forView:cell.imgView withColor:[[FCTheme sharedInstance] channelIconPlaceholderImageBackgroundColor] andName:channel.name];

    }
    [cell adjustPadding];
    return cell;
}

-(FCMessages *)getLastMessageInChannel:(NSNumber *)channelID{
    FCChannels *channel = [FCChannels getWithID:channelID inContext:[FCDataManager sharedInstance].mainObjectContext];
    NSSortDescriptor *sortDesc =[[NSSortDescriptor alloc] initWithKey:@"createdMillis" ascending:YES];
    NSArray *messages = channel.messages.allObjects;
    return [messages sortedArrayUsingDescriptors:@[sortDesc]].lastObject;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)sectionIndex{
    return self.channels.count;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:[self.theme channelCellSelectedColor]];
    [cell setSelectedBackgroundView:view];
    
    if ([tableView respondsToSelector:@selector(setSeparatorInset:)])
    {
        [tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([tableView respondsToSelector:@selector(setLayoutMargins:)])
    {
        [tableView setLayoutMargins:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)])
    {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row < self.channels.count) {
        FCChannels *channel = self.channels[indexPath.row];
        FCMessageController *conversationController = [[FCMessageController alloc]initWithChannelID:channel.channelID andPresentModally:NO];
        FCContainerController *container = [[FCContainerController alloc]initWithController:conversationController andEmbed:NO];
        [FCConversationUtil setConversationOptions:self.convOptions andViewController:conversationController];
        [self.navigationController pushViewController:container animated:YES];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 72;
}

-(void)closeButton:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows]
                     withRowAnimation:UITableViewRowAnimationNone];
}

-(void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message{
    dispatch_async(dispatch_get_main_queue(), ^{ /* show alert view */
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:title message:message delegate:self
                                            cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    });
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == [alertView cancelButtonIndex]){
        self.isJWTAlertShown = FALSE;
    }
}

-(void)dealloc {
    [_loadingViewBehaviour killTimer];
    self.loadingViewBehaviour = nil;
    [self localNotificationUnSubscription];
}

#pragma mark - LoadingView behaviour change

-(FCLoadingViewBehaviour*)loadingViewBehaviour {
    if(_loadingViewBehaviour == nil){
        _loadingViewBehaviour = [[FCLoadingViewBehaviour alloc] initWithViewController:self withType:2];
    }
    return _loadingViewBehaviour;
}

-(UIView *)contentDisplayView{
    return self.tableView;
}

-(NSString *)emptyText{
    return HLLocalizedString(LOC_EMPTY_CHANNEL_TEXT);
}

-(NSString *)loadingText{
    return HLLocalizedString(LOC_LOADING_CHANNEL_TEXT);
}

#pragma mark - Show/Hide JWT Loading/Alert

-(void) showJWTLoading {
    [_loadingViewBehaviour setJWTState:TRUE];
    [_loadingViewBehaviour showLoadingScreen];
    [self.tableView setHidden:true];
}

-(void) hideJWTLoading {
    [_loadingViewBehaviour setJWTState:FALSE];
    [_loadingViewBehaviour hideLoadingScreen];
    [self.tableView setHidden:false];
}

-(void) showJWTVerificationFailedAlert {
    [self showJWTLoading];
    if(!self.isJWTAlertShown) {
        [self showAlertWithTitle:nil
                      andMessage:HLLocalizedString(LOC_JWT_FAILURE_ALERT_MESSAGE)];
        self.isJWTAlertShown = TRUE;
        [_loadingViewBehaviour killTimer];
        if(self.tabBarController != nil) {
            [self.parentViewController.navigationController popViewControllerAnimated:YES];
        } else {
            [self dismissViewControllerAnimated:true completion:nil];
        }
    }
}

@end
