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

@interface FDMessageController () <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSArray *messages;
@property(nonatomic, strong) NSString *conversation;

@end

@implementation FDMessageController

-(instancetype)initWithConversation:(NSString *)conversation{
    self = [super init];
    if (self) {
        self.conversation = conversation;
    }
    return self;
}

-(void)willMoveToParentViewController:(UIViewController *)parent{
    parent.title = self.conversation;
    self.view.backgroundColor = [UIColor whiteColor];
    [self setSubviews];
    [self updateMessages];
}

-(void)updateMessages{
    self.messages = @[@"Welcome to the conversations related to billing",
                      @"how do i book using card",
                      @"you can use this link http://goo.le/d35Gfac"];
}

-(void)setSubviews{
    self.tableView = [[UITableView alloc]init];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.separatorStyle=UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    NSDictionary *views = @{@"tableView" : self.tableView };
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|" options:0 metrics:nil views:views]];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = @"FDMessageCell";
    FDMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[FDMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell initCell];
    }
    
    if (indexPath.row < self.messages.count) {
        //cell.textLabel.text  = self.messages[indexPath.row];
        KonotorMessageData* message=[[KonotorMessageData alloc] init];
        message.messageType=[NSNumber numberWithInt:KonotorMessageTypeText];
        message.text=self.messages[indexPath.row];
        [cell drawMessageViewForMessage:message parentView:self.view];
        
    }
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.messages.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    KonotorMessageData* message=[[KonotorMessageData alloc] init];
    message.messageType=[NSNumber numberWithInt:KonotorMessageTypeText];
    message.text=self.messages[indexPath.row];
    float height=[FDMessageCell getHeightForMessage:message parentView:self.view];
    return height;
}


@end
