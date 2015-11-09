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

@interface HLChannelViewController ()

@property (nonatomic, strong) NSArray *channels;

@end

@implementation HLChannelViewController

-(void)willMoveToParentViewController:(UIViewController *)parent{
    [super willMoveToParentViewController:parent];
    parent.title = @"Channels";
    [self setNavigationItem];
    [self updateChannels];
    [self localNotificationSubscription];
}

-(void)viewWillAppear:(BOOL)animated{
    [self fetchUpdates];
}

-(void)updateChannels{
    [[KonotorDataManager sharedInstance]fetchAllChannels:^(NSArray *channels, NSError *error) {
        if (!error) {
            self.channels = channels;
            [self.tableView reloadData];
        }
    }];
}

-(void)setNavigationItem{
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc]initWithTitle:HLLocalizedString(@"FAQ_GRID_VIEW_CLOSE_BUTTON_TITLE_TEXT") style:UIBarButtonItemStylePlain target:self action:@selector(closeButton:)];
    
    self.parentViewController.navigationItem.leftBarButtonItem = closeButton;
    self.searchDisplayController.displaysSearchBarInNavigationBar = YES;
}

-(void)localNotificationSubscription{
    __weak typeof(self)weakSelf = self;
    [[NSNotificationCenter defaultCenter]addObserverForName:HOTLINE_CHANNELS_UPDATED object:nil queue:nil usingBlock:^(NSNotification *note) {
        HideNetworkActivityIndicator();
        [weakSelf updateChannels];
        NSLog(@"Got Notifications !!!");
    }];
}

-(void)fetchUpdates{
    FDChannelUpdater *updater = [[FDChannelUpdater alloc]init];
    [[KonotorDataManager sharedInstance]areChannelsEmpty:^(BOOL isEmpty) {
        if(isEmpty)[updater resetTime];
        ShowNetworkActivityIndicator();
        [updater fetchWithCompletion:^(BOOL isFetchPerformed, NSError *error) {
            if (!isFetchPerformed) HideNetworkActivityIndicator();
        }];
    }];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = @"HLChannelsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    if (indexPath.row < self.channels.count) {
        HLChannel *channel =  self.channels[indexPath.row];
        cell.textLabel.text  = channel.name;
    }
    return cell;
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)sectionIndex{
    return self.channels.count;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row < self.channels.count) {
        FDMessageController *conversationController = [[FDMessageController alloc]initWithConversation:nil];
        HLContainerController *container = [[HLContainerController alloc]initWithController:conversationController];
        [self.navigationController pushViewController:container animated:YES];
    }
}

-(void)closeButton:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end