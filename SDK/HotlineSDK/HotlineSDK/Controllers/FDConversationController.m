//
//  FDConversationController.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 27/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDConversationController.h"
#import "FDMessageController.h"
#import "HLContainerController.h"

@interface FDConversationController ()

@property(nonatomic, strong) NSArray *conversations;

@end

@implementation FDConversationController

-(void)willMoveToParentViewController:(UIViewController *)parent{
    [super willMoveToParentViewController:parent];
    parent.title = @"Conversations";
    [self updateConversations];
    [self setNavigationItem];
}

-(void)setNavigationItem{
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(closeButton:)];
    self.parentViewController.navigationItem.leftBarButtonItem = closeButton;
}

-(void)closeButton:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)updateConversations{
    self.conversations = @[@"Orders", @"Payments", @"REDCard", @"Return", @"Offers"];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = @"FDConversationsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    if (indexPath.row < self.conversations.count) {
        cell.textLabel.text  = self.conversations[indexPath.row];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"This deals with %@",self.conversations[indexPath.row]];
    }
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.conversations.count;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row < self.conversations.count) {
        NSString *conversation = self.conversations[indexPath.row];
        FDMessageController *messageController = [[FDMessageController alloc]initWithConversation:conversation];
        HLContainerController *container = [[HLContainerController alloc]initWithController:messageController];
        [self.navigationController pushViewController:container animated:YES];
    }
}

@end