//
//  FDAutolayoutHelper.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 19/04/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FCAutolayoutHelper.h"

@implementation FCAutolayoutHelper

+(void)center:(UIView *)subView onView:(UIView *)superView{
    [superView addConstraints:@[[self centerX:subView onView:superView], [self centerY:subView onView:superView]]];
}

+(NSLayoutConstraint *)centerX:(UIView *)subView onView:(UIView *)superView{
    return [self centerX:subView onView:superView M:1 C:0];
}

+(NSLayoutConstraint *)centerY:(UIView *)subView onView:(UIView *)superView{
    return [self centerY:subView onView:superView M:1 C:0];
}

+(NSLayoutConstraint *)centerX:(UIView *)subView onView:(UIView *)superView M:(CGFloat)m C:(CGFloat)c{
    NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:subView attribute:NSLayoutAttributeCenterX
                                    relatedBy:NSLayoutRelationEqual
                                    toItem:superView attribute:NSLayoutAttributeCenterX
                                    multiplier:m constant:c];
    [superView addConstraint:centerXConstraint];
    return centerXConstraint;
}

+(NSLayoutConstraint *)centerY:(UIView *)subView onView:(UIView *)superView M:(CGFloat)m C:(CGFloat)c{
    NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:subView attribute:NSLayoutAttributeCenterY
                                    relatedBy:NSLayoutRelationEqual
                                    toItem:superView attribute:NSLayoutAttributeCenterY
                                    multiplier:m constant:c];
    [superView addConstraint:centerYConstraint];
    return centerYConstraint;
}

+(NSLayoutConstraint *)bottomAlign:(UIView *)subView toView:(UIView *)superView{
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:subView attribute:NSLayoutAttributeBottom
                                                relatedBy:NSLayoutRelationEqual
                                                toItem:superView attribute:NSLayoutAttributeBottom
                                                multiplier:1.0 constant:0.0];
    [superView addConstraint:bottomConstraint];
    return bottomConstraint;
}

+(NSLayoutConstraint *)leftAlign:(UIView *)subView toView:(UIView *)superView{
    return nil;
}

+(NSLayoutConstraint *)setHeight:(CGFloat)height forView:(UIView *)view inView:(UIView *)superView{
   NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight
                                            relatedBy:NSLayoutRelationEqual
                                            toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                            multiplier:1.0 constant:height];
    [superView addConstraint:heightConstraint];
    return heightConstraint;
}

+(NSLayoutConstraint *)setWidth:(CGFloat)width forView:(UIView *)view inView:(UIView *)superView{
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth
                                    relatedBy:NSLayoutRelationEqual
                                    toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                    multiplier:1.0 constant:width];
    [superView addConstraint:widthConstraint];
    return widthConstraint;
}

@end
