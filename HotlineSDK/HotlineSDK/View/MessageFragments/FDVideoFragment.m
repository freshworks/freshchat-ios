//
//  FDVideoFragment.m
//  HotlineSDK
//
//  Created by user on 07/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FDVideoFragment.h"

@implementation FDVideoFragment

    -(id) initWithFragment: (Fragment *) fragment {
        self = [self initWithFrame:CGRectZero];
        if(self) {
            self.translatesAutoresizingMaskIntoConstraints = false;            
        }
        return self;
    }

@end


