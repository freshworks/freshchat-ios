//
//  FDAutolayoutHelper.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 19/04/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FCAutolayoutHelper : NSObject

+(void)center:(UIView *)subView onView:(UIView *)superView;

+(NSLayoutConstraint *)centerX:(UIView *)subView onView:(UIView *)superView;

+(NSLayoutConstraint *)centerY:(UIView *)subView onView:(UIView *)superView;

+(NSLayoutConstraint *)centerX:(UIView *)subView onView:(UIView *)superView M:(CGFloat)m C:(CGFloat)c;

+(NSLayoutConstraint *)centerY:(UIView *)subView onView:(UIView *)superView M:(CGFloat)m C:(CGFloat)c;

+(NSLayoutConstraint *)setHeight:(CGFloat)height forView:(UIView *)view inView:(UIView *)superView;

+(NSLayoutConstraint *)setWidth:(CGFloat)width forView:(UIView *)view inView:(UIView *)superView;

+(NSLayoutConstraint *)leftAlign:(UIView *)subView toView:(UIView *)superView;

+(NSLayoutConstraint *)bottomAlign:(UIView *)subView toView:(UIView *)superView;

//Add a new method, add contraints on view
//Add way to get objects with translateautoresizemask = no

@end
