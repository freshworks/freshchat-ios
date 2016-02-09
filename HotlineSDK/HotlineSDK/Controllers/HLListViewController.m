//
//  HLListViewController.m
//  
//
//  Created by Aravinth Chandran on 23/09/15.
//
//

#import "HLListViewController.h"
#import "HLMacros.h"
#import "HLContainerController.h"
#import "FDMessageController.h"
#import "HLChannelViewController.h"
#import "Hotline.h"

#define CELL_OFFSET 32
#define CEll_HORZ_OFFSET 20

@implementation HLListViewController

-(void)willMoveToParentViewController:(UIViewController *)parent{
    self.view.backgroundColor = [UIColor whiteColor];
    [self setSubviews];
}

-(void)setSubviews{
    self.tableView = [[UITableView alloc]init];
    self.tableView.tableFooterView = [UIView new];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.footerView = [[FDMarginalView alloc] initWithDelegate:self];
    
    [self.view addSubview:self.footerView];
    [self.view addSubview:self.tableView];
    
    NSDictionary *views = @{@"tableView" : self.tableView, @"footerView" : self.footerView };
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:nil views:views]];
    
    if ([self canDisplayFooterView]) {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[footerView]|" options:0 metrics:nil views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView][footerView(40)]|" options:0 metrics:nil views:views]];
    }else{
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|" options:0 metrics:nil views:views]];
    }
}

-(BOOL)canDisplayFooterView{
    return YES;
}

//method to return height of text rect
+ (float) heightOfCell: (NSAttributedString *)textContent{
    
    CGRect rect = [textContent boundingRectWithSize:(CGSize){[UIScreen mainScreen].bounds.size.width - CEll_HORZ_OFFSET, CGFLOAT_MAX} options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    CGSize rectSize = rect.size;
    return rectSize.height + CELL_OFFSET;
}

-(void)marginalView:(FDMarginalView *)marginalView handleTap:(id)sender{
    [[Hotline sharedInstance]presentConversations:self];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"WARNING: Unimplemented method. %@ should implement tableView:cellForRowAtIndexPath" , self.class);
    return nil;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSLog(@"WARNING: Unimplemented method. %@ should implement tableView:numberOfRowsInSection" , self.class);
    return 0;
}

@end