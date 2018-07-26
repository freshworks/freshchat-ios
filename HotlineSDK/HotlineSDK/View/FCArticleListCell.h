//
//  FDArticleListCell.h
//  HotlineSDK
//
//  Created by Harish Kumar on 02/02/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FCArticleListCell : UITableViewCell

@property (strong, nonatomic) UILabel *articleText;
@property (strong, nonatomic) UIView *contentEncloser;

-(void)setupTheme;

// Need to be implemented by subclasses if accessory view is required
//-(void)addAccessoryView;

@end
