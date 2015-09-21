//
//  HLArticlesViewController.m
//  HotlineSDK
//
//  Created by AravinthChandran on 9/9/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "HLArticlesController.h"
#import "WebServices.h"

@interface HLArticlesController () <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, strong)NSArray *dataSource;

@end

@implementation HLArticlesController

- (instancetype)initWithDataSource:(NSArray *)dataSource{
    self = [super init];
    if (self) {
    }
    return self;
}

-(void)willMoveToParentViewController:(UIViewController *)parent{
    parent.title = @"Article List";
    self.tableView = [[UITableView alloc]init];
    self.dataSource = @[@"Item 1", @"Item 2"];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    NSDictionary *views = @{@"tableView" : self.tableView };
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|" options:0 metrics:nil views:views]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self fetchUpdates];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.tableView reloadData];
}

-(void)fetchUpdates{
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)sectionIndex{
    return self.dataSource.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = @"HLArticleCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.textLabel.text  = self.dataSource[indexPath.row];
    return cell;
}

@end