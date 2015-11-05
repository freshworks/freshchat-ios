//
//  HLCollectionView.h
//  HotlineSDK
//
//  Created by kirthikas on 22/09/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDMarginalView.h"

@interface HLCategoryGridViewController : UIViewController<UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,UISearchDisplayDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (strong, nonatomic) NSArray *searchResults;
@property (nonatomic, retain)FDMarginalView *footerView;

@end
