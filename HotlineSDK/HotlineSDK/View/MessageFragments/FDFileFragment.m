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
            self.layer.cornerRadius = 5; // this value vary as per your desire
            [self setBackgroundColor:[UIColor lightGrayColor]];
            self.clipsToBounds = YES;
            NSData *extraJSONData = [fragment.extraJSON dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *extraJSONDict = [NSJSONSerialization JSONObjectWithData:extraJSONData options:0 error:nil];
            self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:13.0f];
            [self setTitle:extraJSONDict[@"label"] forState:UIControlStateNormal];
            [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            self.translatesAutoresizingMaskIntoConstraints = false;
            self.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
            self.userInteractionEnabled = true;
        }
        return self;
    }
@end
