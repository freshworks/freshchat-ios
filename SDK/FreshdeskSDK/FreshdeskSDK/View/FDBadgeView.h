//
//  FDBadgeView.h
//  FreshdeskSDK
//
//  Created by Meera Sundar on 02/06/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDFolderListHeaderView.h"

@interface FDBadgeView : UIView

//Composite Views
@property (strong,nonatomic) UIButton *badgeButton;

//Initializer - requires only origin for the badgeView
-(instancetype)initWithFrame:(CGRect)frame andBadgeNumber:(NSInteger)count;

//Customization
-(void)badgeButtonTitleColor:(UIColor *)color;
-(void)badgeButtonBackgroundColor:(UIColor *)color;
-(void)updateBadgeCount:(NSInteger)count;

@end
