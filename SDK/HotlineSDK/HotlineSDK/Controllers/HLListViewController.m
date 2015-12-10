//
//  HLListViewController.m
//  
//
//  Created by Aravinth Chandran on 23/09/15.
//
//

#import "HLListViewController.h"
#import "KonotorFeedbackScreen.h"

@implementation HLListViewController

-(void)willMoveToParentViewController:(UIViewController *)parent{
    self.view.backgroundColor = [UIColor whiteColor];
    [self setSubviews];
}

-(void)setSubviews{
    self.tableView = [[UITableView alloc]init];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.footerView = [[FDMarginalView alloc] initWithDelegate:self];
    
    [self.view addSubview:self.footerView];
    [self.view addSubview:self.tableView];
    
    NSDictionary *views = @{@"tableView" : self.tableView, @"footerView" : self.footerView };
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[footerView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView][footerView(40)]|" options:0 metrics:nil views:views]];
}

-(void)marginalView:(FDMarginalView *)marginalView handleTap:(id)sender{
    [KonotorFeedbackScreen showFeedbackScreen];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    return nil;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 0;
}

@end