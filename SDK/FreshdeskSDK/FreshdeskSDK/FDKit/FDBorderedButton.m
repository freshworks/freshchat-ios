//
//  FDBorderedButton.m
//  FreshdeskSDK
//
//  Created by AravinthChandran on 16/02/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FDBorderedButton.h"

@implementation FDBorderedButton

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.adjustsFontSizeToFitWidth = YES;
        self.titleEdgeInsets= UIEdgeInsetsMake(0, 5, 0, 5);
        self.layer.borderWidth = 1.0f;
        self.layer.cornerRadius = 5.0f;
     }
    return self;
}

-(void)setBorderColor:(UIColor *)color{
    self.layer.borderColor = [color CGColor];
}



@end
