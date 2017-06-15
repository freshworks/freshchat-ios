//
//  FDDeeplinkFragment.m
//  HotlineSDK
//
//  Created by user on 09/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FDDeeplinkFragment.h"

@implementation FDDeeplinkFragment
    -(id) initWithFragment: (Fragment *) fragment {
        self = [super initWithFrame:CGRectZero];
        if (self) {
            self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
            self.translatesAutoresizingMaskIntoConstraints = NO;
            [self setTitle:@"File" forState:UIControlStateNormal];
            [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            self.backgroundColor = [UIColor lightGrayColor];
            self.translatesAutoresizingMaskIntoConstraints = false;
            self.userInteractionEnabled = true;
        }
        return self;
    }
@end
