//
//  HLChannelViewController.m
//  HotlineSDK
//
//  Created by user on 04/11/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "HLChannelViewController.h"
#import "HLMacros.h"
#import "FCTheme.h"
#import "FDLocalNotification.h"
#import "HLContainerController.h"
#import "FDMessageController.h"
#import "Message.h"
#import "KonotorMessage.h"
#import "KonotorConversation.h"
#import "HLInterstitialViewController.h"
#import "FDDateUtil.h"
#import "FDUtilities.h"
#import "HLLocalization.h"
#import "FDNotificationBanner.h"
#import "FDBarButtonItem.h"
#import "HLEmptyResultView.h"
#import "FDCell.h"
#import "FDAutolayoutHelper.h"
#import "HLMessageServices.h"
#import "FDIconDownloader.h"
#import "FDReachabilityManager.h"
#import "HLTagManager.h"
#import "HLConversationUtil.h"
#import "HLControllerUtils.h"
#import "HLLoadingViewBehaviour.h"
#import "FDSecureStore.h"

@interface HLChannelViewController () <HLLoadingViewBehaviourDelegate>

@property (nonatomic, strong) NSArray *channels;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) HLEmptyResultView *emptyResultView;
@property (nonatomic, strong) FDIconDownloader *iconDownloader;
@property (nonatomic, strong) ConversationOptions *convOptions;
@property (nonatomic, strong) FCTheme *theme;
@property BOOL isFilteredView;
@property (nonatomic, strong) HLLoadingViewBehaviour *loadingViewBehaviour;

@end

@implementation HLChannelViewController

-(HLLoadingViewBehaviour*)loadingViewBehaviour {
    if(_loadingViewBehaviour == nil){
        _loadingViewBehaviour = [[HLLoadingViewBehaviour alloc] initWithViewController:self withType:2];
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

-(void)willMoveToParentViewController:(UIViewController *)parent{
    [super willMoveToParentViewController:parent];
    parent.navigationItem.title = HLLocalizedString(LOC_CHANNELS_TITLE_TEXT);
    self.theme = [FCTheme sharedInstance];
    self.tableView.backgroundColor = [self.theme channelListBackgroundColor];
    HLContainerController * containerCtr =  (HLContainerController*)self.parentViewController;
    [containerCtr.footerView setViewColor:self.tableView.backgroundColor];
    self.navigationController.navigationBar.barTintColor = [self.theme navigationBarBackgroundColor];
    self.navigationController.navigationBar.titleTextAttributes = @{
                                                                    NSForegroundColorAttributeName: [self.theme navigationBarTitleColor],
                                                                    NSFontAttributeName: [self.theme navigationBarTitleFont]
                                                                    };
    self.iconDownloader = [[FDIconDownloader alloc]init];
    [self setNavigationItem];
}

- (void) setConversationOptions:(ConversationOptions *)options{
    self.convOptions = options;
    self.isFilteredView = [HLConversationUtil hasTags:self.convOptions];
}

-(BOOL)canDisplayFooterView{
    return NO;
}

-(void)viewDidLoad{
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.loadingViewBehaviour load:self.channels.count];
    [self loadChannels];
    [self checkRestoreStateChanged];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];    
    [self localNotificationSubscription];
    [self fetchUpdates];
    self.footerView.hidden = YES;
    [self setNavigationItem];
}

-(void)fetchUpdates{
    [[KonotorDataManager sharedInstance]areChannelsEmpty:^(BOOL isEmpty) {
        enum MessageFetchType type = isEmpty ? FetchAll : ScreenLaunchFetch;
        ShowNetworkActivityIndicator();
        [HLMessageServices fetchChannelsAndMessagesWithFetchType:type
                                                          source:ChatScreen
                                                      andHandler:^(NSError *error) {
           HideNetworkActivityIndicator();
        }];
    }];
}

-(void)loadChannels{
    HideNetworkActivityIndicator();
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].mainObjectContext;
    if(self.isFilteredView){
        [[HLTagManager sharedInstance] getChannelsForTags:self.convOptions.tags
                                                    inContext:context
                                               withCompletion:^(NSArray<HLChannel *> *channels){
            
            [self updateChannelWithInfo:channels];
        }];
    }
    else{
        [[KonotorDataManager sharedInstance] fetchAllVisibleChannelsWithCompletion:^(NSArray *channelInfos, NSError *error) {
            if (!error) {
                [self updateChannelWithInfo:channelInfos];
            }
        }];
    }
 }

- (void) updateChannelWithInfo :(NSArray *) channelInfo{
    
    if(self.isFilteredView && channelInfo.count == 0 ){
        HLChannel *defaultChannel = [HLChannel getDefaultChannelInContext:[KonotorDataManager sharedInstance].mainObjectContext];
        if(defaultChannel != nil) {
            channelInfo = @[defaultChannel];
        } else {
            if ( ![[FDReachabilityManager sharedInstance] isReachable]) {
                [self.loadingViewBehaviour updateResultsView:NO andCount:channelInfo.count];
                channelInfo = @[];
            } else {
                return;
            }
        }
    }
    if (channelInfo.count == 1) {
        BOOL isEmbedded = (self.tabBarController != nil) ? YES : NO;
        self.navigationController.viewControllers = @[[HLControllerUtils getConvController:isEmbedded
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
        if ( ![[FDReachabilityManager sharedInstance] isReachable] || refreshData ) {
            [self.loadingViewBehaviour updateResultsView:NO andCount:channelInfo.count];
        }
        [self.tableView reloadData];
    }

}
 

-(NSArray *)sortChannelList:(NSArray *)channelInfos{
    
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    NSMutableArray *messages = [[NSMutableArray alloc]init];
    
    for(HLChannelInfo *channel in channelInfos){
        Message *lastMessage = [self getLastMessageInChannel:channel.channelID];
        if (lastMessage) {
            [messages addObject:lastMessage];
        }
    }
    
    id sort = [NSSortDescriptor sortDescriptorWithKey:@"createdMillis" ascending:NO];
    id positionSort = [NSSortDescriptor sortDescriptorWithKey:@"belongsToChannel.position" ascending:YES];
    messages = [[messages sortedArrayUsingDescriptors:@[sort,positionSort]] mutableCopy];
    for(Message *message in messages){
        if (message.belongsToChannel) {
            HLChannelInfo *chInfo = [[HLChannelInfo alloc] initWithChannel:message.belongsToChannel];
            [results addObject:chInfo];
        }
    }
    return results;
}

-(void)setNavigationItem{
    UIBarButtonItem *closeButton = [[FDBarButtonItem alloc]initWithTitle:HLLocalizedString(LOC_CHANNELS_CLOSE_BUTTON_TEXT) style:UIBarButtonItemStylePlain target:self action:@selector(closeButton:)];

    if (!self.embedded) {
        self.parentViewController.navigationItem.leftBarButtonItem = closeButton;
        [self.navigationController.interactivePopGestureRecognizer setEnabled:NO];
    }
    else {
        [self configureBackButton];
    }
    if([HLConversationUtil hasFilteredViewTitle:self.convOptions]){
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
        HLInterstitialViewController *interstitialController = [[HLInterstitialViewController alloc] initViewControllerWithOptions:self.convOptions andIsEmbed:self.embedded];
        [FDUtilities resetNavigationStackWithController:interstitialController currentController:self];
        [self localNotificationUnSubscription];
    }
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self localNotificationUnSubscription];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"HLChannelsCell";
    
    FDCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[FDCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier isChannelCell:YES];
    }
    
    //Update cell properties
    
    if (indexPath.row < self.channels.count) {
        HLChannelInfo *channel =  self.channels[indexPath.row];

        Message *lastMessage = [self getLastMessageInChannel:channel.channelID];
        cell.separatorInset = UIEdgeInsetsZero;
        cell.titleLabel.text  = channel.name;
        
        cell.tag = indexPath.row;

        NSDate* date=[NSDate dateWithTimeIntervalSince1970:lastMessage.createdMillis.longLongValue/1000];
        
        if([lastMessage.createdMillis intValue]){
           cell.lastUpdatedLabel.text= [FDDateUtil getStringFromDate:date];
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
        


        NSInteger unreadCount = [Message getUnreadMessagesCountForChannel:channel.channelID];
        
        [cell.badgeView updateBadgeCount:unreadCount];

        FDSecureStore *store = [FDSecureStore sharedInstance];
        BOOL showChannelThumbnail = [store boolValueForKey:HOTLINE_DEFAULTS_SHOW_CHANNEL_THUMBNAIL];

        if(showChannelThumbnail){
            if (channel.icon) {
                cell.imgView.image = [UIImage imageWithData:channel.icon];
            }
            else{
                UIImage *placeholderImage = [FDCell generateImageForLabel:channel.name withColor:[self.theme channelIconPlaceholderImageBackgroundColor]];
                NSURL *iconURL = [NSURL URLWithString:channel.iconURL];
                if(iconURL){
                    if (cell.tag == indexPath.row) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            cell.imgView.image = placeholderImage;
                            [cell setNeedsLayout];
                        });
                    }
                    
                    [self.iconDownloader enqueue:^{
                        NSData *imageData = [NSData dataWithContentsOfURL:iconURL];
                        UIImage *image = [[UIImage alloc] initWithData:imageData];
                        if (image) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (cell.tag == indexPath.row) {
                                    cell.imgView.image = image;
                                    [cell setNeedsLayout];
                                    channel.icon = UIImagePNGRepresentation(image);
                                }
                            });
                        }else{
                            dispatch_async(dispatch_get_main_queue(), ^{
                                cell.imgView.image = placeholderImage;
                                [cell setNeedsLayout];
                            });
                        }
                    }];
                }
                else{
                    cell.imgView.image = placeholderImage;
                }
            }
        }

    }
    
    [cell adjustPadding];

    return cell;
}

-(Message *)getLastMessageInChannel:(NSNumber *)channelID{
    HLChannel *channel = [HLChannel getWithID:channelID inContext:[KonotorDataManager sharedInstance].mainObjectContext];
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
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row < self.channels.count) {
        HLChannel *channel = self.channels[indexPath.row];
        FDMessageController *conversationController = [[FDMessageController alloc]initWithChannelID:channel.channelID andPresentModally:NO];
        HLContainerController *container = [[HLContainerController alloc]initWithController:conversationController andEmbed:NO];
        [HLConversationUtil setConversationOptions:self.convOptions andViewController:conversationController];
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

-(void)dealloc{
    [self localNotificationUnSubscription];
}

@end
