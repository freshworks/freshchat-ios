//
//  FDFileFragment.m
//  HotlineSDK
//
//  Created by user on 07/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FDFileFragment.h"

@implementation FDFileFragment
    -(id) initWithFragment: (FragmentData *) fragment {
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
