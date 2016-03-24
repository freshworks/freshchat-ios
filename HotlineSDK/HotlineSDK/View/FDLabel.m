//
//  FDLabel.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 21/03/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FDLabel.h"

@implementation FDLabel

- (id)init {
    self = [super init];
    
    // required to prevent Auto Layout from compressing the label (by 1 point usually) for certain constraint solutions
    [self setContentCompressionResistancePriority:UILayoutPriorityRequired
                                          forAxis:UILayoutConstraintAxisVertical];
    
    return self;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    self.preferredMaxLayoutWidth = CGRectGetWidth(self.bounds);
    [super layoutSubviews];
}

@end
