//
//  HLChannelViewController.m
//  HotlineSDK
//
//  Created by user on 04/11/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "HLChannelViewController.h"
#import "HLMacros.h"
#import "HLTheme.h"
#import "FDLocalNotification.h"
#import "FDChannelUpdater.h"
#import "HLContainerController.h"
#import "FDMessageController.h"
#import "KonotorMessage.h"
#import "KonotorConversation.h"
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
#import "FDControllerUtils.h"

@interface HLChannelViewController ()

@property (nonatomic, strong) NSArray *channels;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) HLEmptyResultView *emptyResultView;
@property (nonatomic, strong) FDIconDownloader *iconDownloader;
@property (nonatomic, strong) HLTheme *theme;

@end

@implementation HLChannelViewController

-(void)willMoveToParentViewController:(UIViewController *)parent{
    [super willMoveToParentViewController:parent];
    parent.navigationItem.title = HLLocalizedString(LOC_CHANNELS_TITLE_TEXT);
    self.theme = [HLTheme sharedInstance];
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                           NSForegroundColorAttributeName: [self.theme channelTitleFontColor],
                                                           NSFontAttributeName: [self.theme channelTitleFont]
                                                           }];
    self.navigationController.navigationBar.barTintColor = [self.theme navigationBarBackgroundColor];
    self.navigationController.navigationBar.titleTextAttributes = @{
                                                                    NSForegroundColorAttributeName: [self.theme navigationBarTitleColor],
                                                                    NSFontAttributeName: [self.theme navigationBarTitleFont]
                                                                    };
    self.iconDownloader = [[FDIconDownloader alloc]init];
    [self setNavigationItem];
    [self addLoadingIndicator];
    [self updateResultsView:YES];
}

-(void)addLoadingIndicator{
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false;
    [self.view insertSubview:self.activityIndicator aboveSubview:self.tableView];
    [self.activityIndicator startAnimating];
    [FDAutolayoutHelper centerX:self.activityIndicator onView:self.view M:1 C:0];
    [FDAutolayoutHelper centerY:self.activityIndicator onView:self.view M:1.5 C:0];
}

-(void)removeLoadingIndicator{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicator removeFromSuperview];
    });
}

-(BOOL)canDisplayFooterView{
    return NO;
}

-(void)viewDidLoad{
    [super viewDidLoad];
    [[[FDChannelUpdater alloc] init] resetTime];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];    
    [self localNotificationSubscription];
    [self fetchUpdates];
    [self updateChannels];
    self.footerView.hidden = YES;
}

-(HLEmptyResultView *)emptyResultView
{
    if (!_emptyResultView) {
        _emptyResultView = [[HLEmptyResultView alloc]initWithImage:[self.theme getImageWithKey:IMAGE_CHANNEL_ICON] andText:@""];
        _emptyResultView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _emptyResultView;
}

-(void)fetchUpdates{
    [[KonotorDataManager sharedInstance]areChannelsEmpty:^(BOOL isEmpty) {
        if(isEmpty){
           [[[FDChannelUpdater alloc]init] resetTime];
        }
        ShowNetworkActivityIndicator();
        [HLMessageServices fetchChannelsAndMessages:^(NSError *error) {
           HideNetworkActivityIndicator();
        }];
    }];
}

-(void)updateChannels{
    HideNetworkActivityIndicator();
    [[KonotorDataManager sharedInstance]fetchAllVisibleChannels:^(NSArray *channelInfos, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                if (channelInfos.count == 1) {
                    BOOL isEmbedded = (self.tabBarController != nil) ? YES : NO;
                    self.navigationController.viewControllers = @[[FDControllerUtils getConvController:isEmbedded]];
                }else{
                    BOOL refreshData = NO;
                    NSArray *sortedChannel = [self sortChannelList:channelInfos];
                    if ( self.channels ) {
                        refreshData = YES;
                    }
                    self.channels = sortedChannel;
                    refreshData = refreshData || (self.channels.count > 0);
                    if ( ![[FDReachabilityManager sharedInstance] isReachable] || refreshData ) {
                        [self updateResultsView:NO];
                    }
                    [self.tableView reloadData];
                }
            }
        });
    }];
}

-(NSArray *)sortChannelList:(NSArray *)channelInfos{
    
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    NSMutableArray *messages = [[NSMutableArray alloc]init];
    
    for(HLChannelInfo *channel in channelInfos){
        KonotorMessage *lastMessage = [self getLastMessageInChannel:channel.channelID];
        if (lastMessage) {
            [messages addObject:lastMessage];
        }
    }
    
    id sort = [NSSortDescriptor sortDescriptorWithKey:@"createdMillis" ascending:NO];
    messages = [[messages sortedArrayUsingDescriptors:@[sort]] mutableCopy];
    
    for(KonotorMessage *message in messages){
        if (message.belongsToChannel) {
            HLChannelInfo *chInfo = [[HLChannelInfo alloc] initWithChannel:message.belongsToChannel];
            [results addObject:chInfo];
        }
    }
    
    return results;
}

-(void)updateResultsView:(BOOL)isLoading
{
    if(self.channels.count == 0) {
        NSString *message;
        if(isLoading) {
            message = HLLocalizedString(LOC_LOADING_CHANNEL_TEXT);
        }
        else if(![[FDReachabilityManager sharedInstance] isReachable]){
            message = HLLocalizedString(LOC_OFFLINE_INTERNET_MESSAGE);
            [self removeLoadingIndicator];
        }
        else {
            message = HLLocalizedString(LOC_EMPTY_CHANNEL_TEXT);
            [self removeLoadingIndicator];
        }
        self.emptyResultView.emptyResultLabel.text = message;
        [self.view addSubview:self.emptyResultView];
        [FDAutolayoutHelper center:self.emptyResultView onView:self.view];
    }
    else{
        self.emptyResultView.frame = CGRectZero;
        [self.emptyResultView removeFromSuperview];
        [self removeLoadingIndicator];
    }
}

-(void)setNavigationItem{
    UIBarButtonItem *closeButton = [[FDBarButtonItem alloc]initWithTitle:HLLocalizedString(LOC_CHANNELS_CLOSE_BUTTON_TEXT) style:UIBarButtonItemStylePlain target:self action:@selector(closeButton:)];

    if (!self.embedded) {
        self.parentViewController.navigationItem.leftBarButtonItem = closeButton;
    }
    else {
        [self configureBackButtonWithGestureDelegate:nil];
    }
}

-(void)localNotificationSubscription{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateChannels)
                                                 name:HOTLINE_MESSAGES_DOWNLOADED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateChannels)
                                                 name:HOTLINE_CHANNELS_UPDATED object:nil];
}

-(void)localNotificationUnSubscription{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HOTLINE_MESSAGES_DOWNLOADED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HOTLINE_CHANNELS_UPDATED object:nil];
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

        KonotorMessage *lastMessage = [self getLastMessageInChannel:channel.channelID];
        
        cell.titleLabel.text  = channel.name;
        
        cell.tag = indexPath.row;

        NSDate* date=[NSDate dateWithTimeIntervalSince1970:lastMessage.createdMillis.longLongValue/1000];
        
        if([lastMessage.createdMillis intValue]){
           cell.lastUpdatedLabel.text= [FDDateUtil getStringFromDate:date];
        }
        else{
            cell.lastUpdatedLabel.text = nil;
        }

        cell.detailLabel.text = [self getDetailDescriptionForMessage:lastMessage];


        NSInteger unreadCount = [KonotorMessage getUnreadMessagesCountForChannel:channel.channelID];
        
        [cell.badgeView updateBadgeCount:unreadCount];

        FDSecureStore *store = [FDSecureStore sharedInstance];
        BOOL showChannelThumbnail = [store boolValueForKey:HOTLINE_DEFAULTS_SHOW_CHANNEL_THUMBNAIL];

        if(showChannelThumbnail){
            if (channel.icon) {
                cell.imgView.image = [UIImage imageWithData:channel.icon];
            }
            else{
                UIImage *placeholderImage = [FDCell generateImageForLabel:channel.name];
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

-(NSString *)getDetailDescriptionForMessage:(KonotorMessage *)message{
    
    NSString *description = nil;

    NSInteger messageType = message.messageType.integerValue;
    
    switch (messageType) {
        case KonotorMessageTypeText:
            description = message.text;
            break;
            
        case KonotorMessageTypeAudio:
            description = HLLocalizedString(LOC_AUDIO_MSG_TITLE);
            break;
            
        case KonotorMessageTypePicture:
        case KonotorMessageTypePictureV2:{
            if (message.text) {
                description = message.text;
            }else{
                description = HLLocalizedString(LOC_PICTURE_MSG_TITLE);
            }
            break;
        }
            
        default:
            description = message.text;
            break;
    }
    
    return description;
}

-(KonotorMessage *)getLastMessageInChannel:(NSNumber *)channelID{
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

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row < self.channels.count) {
        HLChannel *channel = self.channels[indexPath.row];
        FDMessageController *conversationController = [[FDMessageController alloc]initWithChannelID:channel.channelID andPresentModally:NO];
        HLContainerController *container = [[HLContainerController alloc]initWithController:conversationController andEmbed:NO];
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
