//
//  FDBadgeView.h
//  FreshdeskSDK
//
//  Created by Meera Sundar on 02/06/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FCLabel.h"

@interface FCBadgeView : UIView

@property (nonatomic, strong) FCLabel *countLabel;

-(instancetype)initWithFrame:(CGRect)frame;

-(void)updateBadgeCount:(NSInteger)count;

@end
