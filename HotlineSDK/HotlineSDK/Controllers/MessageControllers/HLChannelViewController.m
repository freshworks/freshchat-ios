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
#import "HLChannel.h"
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
#import "FDChannelUpdater.h"
#import "FDIconDownloader.h"
#import "FDReachabilityManager.h"

@interface HLChannelViewController ()

@property (nonatomic, strong) NSArray *channels;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) HLEmptyResultView *emptyResultView;
@property (nonatomic, strong) FDIconDownloader *iconDownloader;

@end

@implementation HLChannelViewController

-(void)willMoveToParentViewController:(UIViewController *)parent{
    [super willMoveToParentViewController:parent];
    parent.navigationItem.title = HLLocalizedString(LOC_CHANNELS_TITLE_TEXT);
    HLTheme *theme = [HLTheme sharedInstance];
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                           NSForegroundColorAttributeName: [theme channelTitleFontColor],
                                                           NSFontAttributeName: [theme channelTitleFont]
                                                           }];
    self.navigationController.navigationBar.barTintColor = [theme navigationBarBackgroundColor];
    self.navigationController.navigationBar.titleTextAttributes = @{
                                                                    NSForegroundColorAttributeName: [theme navigationBarTitleColor],
                                                                    NSFontAttributeName: [theme navigationBarTitleFont]
                                                                    };
    self.channels = [[NSMutableArray alloc] init];
    self.iconDownloader = [[FDIconDownloader alloc]init];
    [self setNavigationItem];
    [self addLoadingIndicator];
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

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self localNotificationSubscription];
    [self fetchUpdates];
    self.footerView.hidden = YES;
}

-(void)fetchUpdates{
    [self updateChannels];
    [[KonotorDataManager sharedInstance]areChannelsEmpty:^(BOOL isEmpty) {
        if(isEmpty){
           [[[FDChannelUpdater alloc]init] resetTime];
        }
        else {
            [self removeLoadingIndicator];
        }
        ShowNetworkActivityIndicator();
        [HLMessageServices fetchChannelsAndMessages:^(NSError *error) {
            HideNetworkActivityIndicator();
            if(isEmpty){
                [self removeLoadingIndicator];
            }
        }];
    }];
}

-(void)updateChannels{
    HideNetworkActivityIndicator();
    [[KonotorDataManager sharedInstance]fetchAllVisibleChannels:^(NSArray *channels, NSError *error) {
        if (!error) {
            NSMutableArray *messages = [NSMutableArray array];
            for(HLChannel *channel in channels){
                KonotorMessage *lastMessage = [self getLastMessageInChannel:channel];
                if (lastMessage) {
                    [messages addObject:lastMessage];
                }
            }
            
            id sort = [NSSortDescriptor sortDescriptorWithKey:@"createdMillis" ascending:NO];
            messages = [[messages sortedArrayUsingDescriptors:@[sort]] mutableCopy];
            
            NSMutableArray *sortedChannel = [[NSMutableArray alloc] init];
            for(KonotorMessage *message in messages){
                if (message.belongsToChannel) {
                    [sortedChannel addObject:message.belongsToChannel];
                }
            }
            
            self.channels = sortedChannel;
            if(!self.channels.count){
                HLTheme *theme = [HLTheme sharedInstance];
                if (!self.emptyResultView) {
                    NSString *message;
                    if([[FDReachabilityManager sharedInstance] isReachable]){
                        message = HLLocalizedString(LOC_EMPTY_CHANNEL_TEXT);
                    }
                    else{
                        message = HLLocalizedString(LOC_OFFLINE_INTERNET_MESSAGE);
                        [self removeLoadingIndicator];
                    }
                    self.emptyResultView = [[HLEmptyResultView alloc]initWithImage:[theme getImageWithKey:IMAGE_CHANNEL_ICON] andText:message];
                    self.emptyResultView.translatesAutoresizingMaskIntoConstraints = NO;
                    [self.view addSubview:self.emptyResultView];
                    [FDAutolayoutHelper center:self.emptyResultView onView:self.view];
                }
            }
            else{
                self.emptyResultView.frame = CGRectZero;
                [self.emptyResultView removeFromSuperview];
            }
            [self.tableView reloadData];
        }
    }];
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

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HOTLINE_MESSAGES_DOWNLOADED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HOTLINE_CHANNELS_UPDATED object:nil];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"HLChannelsCell";
    
    FDCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[FDCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier isChannelCell:YES];
    }
    
    //Update cell properties
    
    if (indexPath.row < self.channels.count) {
        HLChannel *channel =  self.channels[indexPath.row];

        KonotorMessage *lastMessage = [self getLastMessageInChannel:channel];
        
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


        NSInteger *unreadCount = [KonotorMessage getUnreadMessagesCountForChannel:channel];
        
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
                        cell.imgView.image = placeholderImage;
                        [cell setNeedsLayout];
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
                                    [[KonotorDataManager sharedInstance]save];
                                }
                            });
                        }else{
                            cell.imgView.image = placeholderImage;
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

-(KonotorMessage *)getLastMessageInChannel:(HLChannel *)channel{
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
        FDMessageController *conversationController = [[FDMessageController alloc]initWithChannel:channel andPresentModally:NO];
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

@end