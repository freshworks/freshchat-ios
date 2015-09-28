//
//  HLCategoriesListController.m
//  
//
//  Created by Aravinth Chandran on 23/09/15.
//
//

#import "HLCategoriesListController.h"
#import "HLFAQServices.h"
#import "HLLocalNotification.h"
#import "KonotorDataManager.h"
#import "HLCategory.h"
#import "HLArticlesController.h"
#import "HLContainerController.h"
#import "HLLocalNotification.h"

@implementation HLCategoriesListController

-(void)willMoveToParentViewController:(UIViewController *)parent{
    [super willMoveToParentViewController:parent];
    parent.title = @"Categories";
    [self setNavigationItem];
    [self updateDataSource];
    [self fetchUpdates];
    [self localNotificationSubscription];
}

-(void)updateDataSource{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"HLCategory"];
    NSSortDescriptor *position   = [NSSortDescriptor sortDescriptorWithKey:@"position" ascending:YES];
    request.sortDescriptors = @[position];
    NSError *error;
    NSArray *results =[[KonotorDataManager sharedInstance].mainObjectContext executeFetchRequest:request error:&error];
    if (results) {
        self.dataSource = results;
        [self.tableView reloadData];
    }
}

-(void)setNavigationItem{
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(closeButton:)];
    [self.parentViewController.navigationItem setLeftBarButtonItem:closeButton];
}

-(void)closeButton:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)localNotificationSubscription{
    [[NSNotificationCenter defaultCenter]addObserverForName:HOTLINE_SOLUTIONS_UPDATED object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self updateDataSource];
        NSLog(@"Got Notifications !!!");
    }];
}

-(void)fetchUpdates{
    HLFAQServices *service = [HLFAQServices new];
    [service fetchSolutions];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = @"HLCategoriesCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    HLCategory *category =  self.dataSource[indexPath.row];
    cell.textLabel.text  = category.title;
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    HLCategory *category =  self.dataSource[indexPath.row];
    HLArticlesController *articleController = [[HLArticlesController alloc]initWithCategory:category];
    HLContainerController *container = [[HLContainerController alloc]initWithController:articleController];
    [self.navigationController pushViewController:container animated:YES];
}

@end
