//
//  HLCollectionView.m
//  HotlineSDK
//
//  Created by kirthikas on 22/09/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "HLCategoryGridViewController.h"
#import "HLGridViewCell.h"
#import "HLContainerController.h"
#import "HLArticlesController.h"
#import "KonotorDataManager.h"
#import "HLArticlesController.h"
#import "HLLocalNotification.h"
#import "HLCategory.h"
#import "FDSolutionUpdater.h"

@interface HLCategoryGridViewController ()

@property (nonatomic,strong) NSArray *categories;

@end

@implementation HLCategoryGridViewController

-(void)willMoveToParentViewController:(UIViewController *)parent{
    parent.title = @"Collections View";
    self.view.backgroundColor = [UIColor whiteColor];
    [self updateCategories];
    [self setupCollectionView];
    [self setNavigationItem];
    [self fetchUpdates];
    [self localNotificationSubscription];
}

-(void)setNavigationItem{
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(closeButton:)];
    [self.parentViewController.navigationItem setLeftBarButtonItem:closeButton];
}

-(void)updateCategories{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_CATEGORY_ENTITY];
    NSSortDescriptor *position   = [NSSortDescriptor sortDescriptorWithKey:@"position" ascending:YES];
    request.sortDescriptors = @[position];
    NSError *error;
    NSArray *results =[[KonotorDataManager sharedInstance].mainObjectContext executeFetchRequest:request error:&error];
    if (results) {
        self.categories = results;
        [self.collectionView reloadData];
    }
}

-(void)fetchUpdates{
    FDSolutionUpdater *updater = [[FDSolutionUpdater alloc]init];
    [[KonotorDataManager sharedInstance]areSolutionsEmpty:^(BOOL isEmpty) {
        if(isEmpty){
            [updater resetTime];
        }
        [updater fetch];
    }];
}

-(void)closeButton:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)localNotificationSubscription{
    [[NSNotificationCenter defaultCenter]addObserverForName:HOTLINE_SOLUTIONS_UPDATED object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self updateCategories];
        NSLog(@"Got Notifications !!!");
    }];
}

-(void)setupCollectionView{
    UICollectionViewFlowLayout* flowLayout = [[UICollectionViewFlowLayout alloc]init];
    self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.collectionView];
    
    NSDictionary *views = @{ @"collectionView" : self.collectionView };
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[collectionView]-10-|"
                                                                      options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[collectionView]|" options:0 metrics:nil views:views]];
    
    //Collection view subclass
    [self.collectionView registerClass:[HLGridViewCell class] forCellWithReuseIdentifier:@"FAQ_GRID_CELL"];
}

#pragma mark - Collection view delegat0e

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    NSInteger noOfItems = [self.categories count];
    if (!noOfItems) {
        return 0;
    }
    return self.categories.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HLGridViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"FAQ_GRID_CELL" forIndexPath:indexPath];
    cell.imageView.image = [UIImage imageNamed:@"konotor_profile.png"];
    HLCategory *category = self.categories[indexPath.row];
    cell.label.text = category.title;
    cell.label.font = [UIFont systemFontOfSize:14];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake( ([UIScreen mainScreen].bounds.size.height/5)+15, ([UIScreen mainScreen].bounds.size.height/5)+15);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    HLCategory *category = self.categories[indexPath.row];
    HLArticlesController *articleController = [[HLArticlesController alloc] initWithCategory:category];
    HLContainerController *container = [[HLContainerController alloc]initWithController:articleController];
    [self.navigationController pushViewController:container animated:YES];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return [UIScreen mainScreen].bounds.size.width/25;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return [UIScreen mainScreen].bounds.size.height/25;
}

// Layout: Set Edges
- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(15,15,15,15);  // top, left, bottom, right
}

- (NSArray *) layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *layoutForCells = [self.collectionView.collectionViewLayout layoutAttributesForElementsInRect:rect];
    for(int i = 1; i < [layoutForCells count]; ++i) {
        UICollectionViewLayoutAttributes *currentLayoutAttributes = layoutForCells[i];
        UICollectionViewLayoutAttributes *prevLayoutAttributes = layoutForCells[i - 1];
        NSInteger maximumSpacing = 4;
        NSInteger origin = CGRectGetMaxX(prevLayoutAttributes.frame);
        if(origin + maximumSpacing + currentLayoutAttributes.frame.size.width < 10) {
            CGRect frame = currentLayoutAttributes.frame;
            frame.origin.x = origin + maximumSpacing;
            currentLayoutAttributes.frame = frame;
        }
    }
    return layoutForCells;
}

@end
