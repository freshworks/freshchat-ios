//
//  FDBadgeView.h
//  FreshdeskSDK
//
//  Created by Meera Sundar on 02/06/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDLabel.h"

@interface FDBadgeView : UIView

@property (nonatomic, strong) FDLabel *countLabel;

-(instancetype)initWithFrame:(CGRect)frame;

-(void)updateBadgeCount:(NSInteger)count;

@end
