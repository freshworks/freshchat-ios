//
//  FDFolderListHeaderView.h
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 27/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FDFolderListHeaderView : UIView

@property (nonatomic) NSInteger badgeCount;

//Initializer
-(instancetype)initWithFrame:(CGRect)frame;

//Badge View
-(void)badgeViewTitleColor:(UIColor *)color;
-(void)badgeViewBackgroundColor:(UIColor *)color;
-(void)updateBadgeButtonCount:(NSInteger)count;
-(void)removeBadgeView;
-(void)hideBadgeView;

//My Conversations View Theming
-(void)myConversationsViewFont:(UIFont *)font;
-(void)myConversationsViewFontColor:(UIColor *)color;
-(void)myConversationsViewBackgroundColor:(UIColor *)color;

//Others
-(void)tapGestureHander:(SEL)handler onController:(UIViewController *)controller;

@end