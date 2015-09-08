//
//  KonotorImageView.h
//  KonotorDemo
//
//  Created by Srikrishnan Ganesan on 12/05/14.
//  Copyright (c) 2014 Demach. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface KonotorImageView : UIScrollView <UIScrollViewDelegate>

@property (nonatomic, strong) UIView * backgroundView;
@property (nonatomic, strong) UIImageView* imageView;
@property (nonatomic, strong) UIImage* img;
@property (nonatomic, strong) NSURL* imgURL;
@property (nonatomic) float imgHeight,imgWidth;

@property (nonatomic, weak) UIViewController* sourceViewController;

- (void) showImageView;
- (void) rotateToOrientation:(UIInterfaceOrientation) orientation duration:(NSTimeInterval) duration;


@end
