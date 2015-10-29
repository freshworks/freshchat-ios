//
//  FDMarginalView.h
//  HotlineSDK
//
//  Created by user on 28/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HLTheme.h"

@interface FDMarginalView : UIView

@property (nonatomic,strong) UILabel *marginalLabel;
@property (nonatomic,strong) HLTheme *theme;

-(void)setLabelText:(NSString *)text;

@end
