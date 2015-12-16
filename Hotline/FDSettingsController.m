//
//  FDSettingsController.m
//  Hotline
//
//  Created by Aravinth Chandran on 29/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDSettingsController.h"
#import "HotlineSDK/Hotline.h"

@interface FDSettingsController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSArray *items;
@property(nonatomic, strong) UITableView *tableView;

@end

@implementation FDSettingsController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.items = @[@"List/Grid", @"Clear user data"];
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc]initWithTitle:@"close" style:UIBarButtonItemStylePlain target:self action:@selector(closeButton:)];
    self.navigationItem.leftBarButtonItem = closeButton;
    [self setSubviews];
}


-(void)closeButton:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)setSubviews{
    self.tableView = [[UITableView alloc]init];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    
    NSDictionary *views = @{@"tableView" : self.tableView };
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|" options:0 metrics:nil views:views]];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = @"HLSettingsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    NSString *item = self.items[indexPath.row];
    
    if ([item isEqualToString:@"List/Grid"]) {
        UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
        cell.accessoryView = switchView;
        [switchView setOn:[Hotline sharedInstance].displaySolutionsAsGrid animated:NO];
        [switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    }
    
    cell.textLabel.text = self.items[indexPath.row];
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.items.count;
}

- (void) switchChanged:(id)sender {
    UISwitch* switchControl = sender;
    [Hotline sharedInstance].displaySolutionsAsGrid = switchControl.on;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *item = self.items[indexPath.row];
    if ([item isEqualToString:@"Clear user data"]) {
        [[Hotline sharedInstance]clearUserData];
    }
}

@end