//
//  HLListViewController.m
//  
//
//  Created by Aravinth Chandran on 23/09/15.
//
//

#import "HLListViewController.h"
#import "KonotorFeedbackScreen.h"
#import "HLMacros.h"

@implementation HLListViewController

-(void)willMoveToParentViewController:(UIViewController *)parent{
    self.view.backgroundColor = [UIColor whiteColor];
    [self setSubviews];
}

-(void)setSubviews{
    self.tableView = [[UITableView alloc]init];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.footerView = [[FDMarginalView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), 44)];
    self.footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.footerView.marginalLabel.text = HLLocalizedString(@"CATEGORIES_LIST_VIEW_FOOTER_LABEL");
    self.footerView.marginalLabel.textColor = [UIColor blackColor];
    self.footerView.marginalLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.footerView.marginalLabel.backgroundColor = [UIColor clearColor];
    self.footerView.marginalLabel.userInteractionEnabled=YES;
    UIGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self.footerView.marginalLabel addGestureRecognizer: tapGesture];
    self.footerView.backgroundColor = [UIColor colorWithRed:0.08 green:0.46 blue:1 alpha:1];
    
    self.tableView.tableFooterView = self.footerView;
    [self.view addSubview:self.tableView];
    
    NSDictionary *views = @{@"tableView" : self.tableView };
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|" options:0 metrics:nil views:views]];
}

-(void)handleTapGesture: (UIGestureRecognizer*) recognizer{
    [KonotorFeedbackScreen showFeedbackScreen];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    return nil;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 0;
}

@end