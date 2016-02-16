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
#import "FDChannelListViewCell.h"
#import "KonotorMessage.h"
#import "KonotorConversation.h"
#import "FDDateUtil.h"
#import "FDUtilities.h"
#import "HLLocalization.h"
#import "FDNotificationBanner.h"

@interface HLChannelViewController ()

@property (nonatomic, strong) NSArray *channels;
@property (strong, nonatomic) UIImageView *emptyChannelImgView;
@property (strong, nonatomic) UILabel *emptyChanneltLbl;

@end

@implementation HLChannelViewController

-(void)willMoveToParentViewController:(UIViewController *)parent{
    [super willMoveToParentViewController:parent];
    parent.title = HLLocalizedString(LOC_CHANNELS_TITLE_TEXT);
    HLTheme *theme = [HLTheme sharedInstance];
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                           NSForegroundColorAttributeName: [theme channelTitleFontColor],
                                                           NSFontAttributeName: [theme channelTitleFont]
                                                           }];
    self.channels = [[NSMutableArray alloc] init];
    [self setNavigationItem];
    [self localNotificationSubscription];
}

-(BOOL)canDisplayFooterView{
    return NO;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self fetchUpdates];
    self.footerView.hidden = YES;
}

-(void)fetchUpdates{
    [self updateChannels];
    FDChannelUpdater *updater = [[FDChannelUpdater alloc]init];
    [[KonotorDataManager sharedInstance]areChannelsEmpty:^(BOOL isEmpty) {
        if(isEmpty)[updater resetTime];
        ShowNetworkActivityIndicator();
        [updater fetchWithCompletion:^(BOOL isFetchPerformed, NSError *error) {
            if (!isFetchPerformed) HideNetworkActivityIndicator();
        }];
    }];
}

-(void)updateChannels{
    [[KonotorDataManager sharedInstance]fetchAllVisibleChannels:^(NSArray *channels, NSError *error) {
        if (!error) {
            NSMutableArray *messages = [NSMutableArray array];
            for(HLChannel *channel in channels){
                KonotorMessage *lastMessage = [self getLastMessageInChannel:channel];
                [messages addObject:lastMessage];
            }
            
            id sort = [NSSortDescriptor sortDescriptorWithKey:@"createdMillis" ascending:NO];
            messages = [[messages sortedArrayUsingDescriptors:@[sort]] mutableCopy];
            
            NSMutableArray *sortedChannel = [[NSMutableArray alloc] init];
            for(KonotorMessage *message in messages){
                [sortedChannel addObject:message.belongsToChannel];
            }
            
            self.channels = sortedChannel;
            if(!self.channels.count){
                
                self.emptyChannelImgView = [[UIImageView alloc] init];
                HLTheme *theme = [HLTheme sharedInstance];
                self.emptyChannelImgView.image = [theme getImageWithKey:IMAGE_CHANNEL_ICON];
                [self.emptyChannelImgView setTranslatesAutoresizingMaskIntoConstraints:NO];
                [self.view addSubview:self.emptyChannelImgView];
                
                self.emptyChanneltLbl = [[UILabel alloc]init];
                self.emptyChanneltLbl.translatesAutoresizingMaskIntoConstraints = NO;
                self.emptyChanneltLbl.textColor = [theme dialogueTitleTextColor];
                self.emptyChanneltLbl.font = [theme dialogueTitleFont];
                self.emptyChanneltLbl.lineBreakMode = NSLineBreakByWordWrapping;
                self.emptyChanneltLbl.numberOfLines = 2;
                self.emptyChanneltLbl.textAlignment= NSTextAlignmentCenter;
                self.emptyChanneltLbl.text = HLLocalizedString(LOC_EMPTY_CHANNEL_TEXT);
                [self.view addSubview:self.emptyChanneltLbl];
                
                [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.emptyChannelImgView
                                                                      attribute:NSLayoutAttributeCenterX
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.tableView
                                                                      attribute:NSLayoutAttributeCenterX
                                                                     multiplier:1.0
                                                                       constant:0.0]];
                
                [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.emptyChannelImgView
                                                                      attribute:NSLayoutAttributeCenterY
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.tableView
                                                                      attribute:NSLayoutAttributeCenterY
                                                                     multiplier:1.0
                                                                       constant:0.0]];
                
                NSDictionary *emptychannelViews = @{@"emptyChannelImag":self.emptyChannelImgView, @"emptyChannelLbl" : self.emptyChanneltLbl};
                
                [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-50-[emptyChannelLbl]-50-|" options:0 metrics:nil views:emptychannelViews]];
                
                [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[emptyChannelImag]-10-[emptyChannelLbl]" options:0 metrics:nil views:emptychannelViews]];
            }
            else{
                [self.emptyChannelImgView removeFromSuperview];
                [self.emptyChanneltLbl removeFromSuperview];
            }
            [self.tableView reloadData];
        }
    }];
}

-(void)setNavigationItem{
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc]initWithTitle:HLLocalizedString(LOC_CHANNELS_CLOSE_BUTTON_TEXT) style:UIBarButtonItemStylePlain target:self action:@selector(closeButton:)];
    BOOL isEmbeddable = ((HLContainerController *)self.parentViewController).isEmbeddable;
    if (!isEmbeddable) {
        self.parentViewController.navigationItem.leftBarButtonItem = closeButton;
    }
    self.searchDisplayController.displaysSearchBarInNavigationBar = YES;
}

-(void)localNotificationSubscription{
    __weak typeof(self)weakSelf = self;
    [[NSNotificationCenter defaultCenter]addObserverForName:HOTLINE_MESSAGES_DOWNLOADED object:nil queue:nil usingBlock:^(NSNotification *note) {
        HideNetworkActivityIndicator();
        [weakSelf updateChannels];
    }];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = @"HLChannelsCell";
    FDChannelListViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[FDChannelListViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    if (indexPath.row < self.channels.count) {
        HLChannel *channel =  self.channels[indexPath.row];
        KonotorMessage *lastMessage = [self getLastMessageInChannel:channel];
        
        cell.titleLabel.text  = channel.name;
        
        NSDate* date=[NSDate dateWithTimeIntervalSince1970:lastMessage.createdMillis.longLongValue/1000];
        cell.lastUpdatedLabel.text= [FDDateUtil getStringFromDate:date];

        cell.detailLabel.text = [self getDetailDescriptionForMessage:lastMessage];
        
        if (channel.icon) {
            cell.imgView.image = [UIImage imageWithData:channel.icon];
        }
        else{
            UIImage *placeholderImage = [FDChannelListViewCell generateImageForLabel:channel.name];
            if(channel.iconURL){
                NSURL *iconURL = [[NSURL alloc]initWithString:channel.iconURL];
                NSURLRequest *request = [[NSURLRequest alloc]initWithURL:iconURL];
                __weak FDChannelListViewCell *weakCell = cell;
                [cell.imgView setImageWithURLRequest:request placeholderImage:placeholderImage success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                    weakCell.imgView.image = image;
                    channel.icon = UIImagePNGRepresentation(image);
                    [[KonotorDataManager sharedInstance]save];
                } failure:nil];
            }
            else{
                cell.imgView.image = placeholderImage;
            }
        }
        
        NSInteger *unreadCount = [KonotorMessage getUnreadMessagesCountForChannel:channel];
        [cell.badgeView updateBadgeCount:unreadCount];
    }
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
        HLContainerController *container = [[HLContainerController alloc]initWithController:conversationController];
        [self.navigationController pushViewController:container animated:YES];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 72;
}

-(void)closeButton:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end