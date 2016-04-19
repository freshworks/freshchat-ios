//
//  FDAutolayoutHelper.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 19/04/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FDAutolayoutHelper : NSObject

+(void)center:(UIView *)subView onView:(UIView *)superView;
+(NSLayoutConstraint *)leftAlign:(UIView *)subView toView:(UIView *)superView;
+(NSLayoutConstraint *)setHeight:(CGFloat)height forView:(UIView *)view;
+(NSLayoutConstraint *)setWidth:(CGFloat)width forView:(UIView *)view;

@end