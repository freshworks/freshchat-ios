//
//  FDAutolayoutHelper.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 19/04/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FDAutolayoutHelper.h"

@implementation FDAutolayoutHelper

+(void)center:(UIView *)subView onView:(UIView *)superView{
    
    NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:superView
                                                               attribute:NSLayoutAttributeCenterX
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:subView
                                                               attribute:NSLayoutAttributeCenterX
                                                              multiplier:1.0
                                                                constant:0.0];
    
    NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:superView
                                                               attribute:NSLayoutAttributeCenterY
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:subView
                                                               attribute:NSLayoutAttributeCenterY
                                                              multiplier:1.0
                                                                constant:0.0];
    [superView addConstraints:@[centerX, centerY]];
}

+(NSLayoutConstraint *)leftAlign:(UIView *)subView toView:(UIView *)superView{
    return nil;
}

+(NSLayoutConstraint *)setHeight:(CGFloat)height forView:(UIView *)view{
   return [NSLayoutConstraint constraintWithItem:view
                                 attribute:NSLayoutAttributeHeight
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:nil
                                 attribute:NSLayoutAttributeNotAnAttribute
                                multiplier:1.0
                                  constant:height];
}

+(NSLayoutConstraint *)setWidth:(CGFloat)width forView:(UIView *)view{
    return [NSLayoutConstraint constraintWithItem:view
                                        attribute:NSLayoutAttributeWidth
                                        relatedBy:NSLayoutRelationEqual
                                           toItem:nil
                                        attribute:NSLayoutAttributeNotAnAttribute
                                       multiplier:1.0
                                         constant:width];
}


@end
