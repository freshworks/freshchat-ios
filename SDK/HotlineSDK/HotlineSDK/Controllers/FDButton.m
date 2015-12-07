//
//  FDButton.m
//  FreshdeskSDK
//
//  Created by Aravinth on 18/07/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDButton.h"

@implementation FDButton

//All properties are set to nil so that the button doesn't get fucked up somewhere

// CHECK :
// Suggesstion : May be add theme defaults here ( of course only if gets called ). 

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor      = nil;
        self.titleLabel.tintColor = nil;
        self.tintColor            = nil;
        [self setTitleColor:nil forState:UIControlStateNormal];
        self.titleLabel.font      = [UIFont boldSystemFontOfSize:18.0f];
    }
    return self;
}

@end
