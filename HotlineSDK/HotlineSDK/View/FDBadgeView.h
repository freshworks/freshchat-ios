//
//  FDBadgeView.h
//  FreshdeskSDK
//
//  Created by Meera Sundar on 02/06/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FDBadgeView : UIView

//Composite Views
@property (strong,nonatomic) UIButton *badgeButton;

//Initializer - requires only origin for the badgeView
-(instancetype)initWithFrame:(CGRect)frame andBadgeNumber:(NSInteger)count;

-(void)updateBadgeCount:(NSInteger)count;

@end
