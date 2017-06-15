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
            self.numberOfLines = 0;
            self.text = @"Asynchronous image downloader with cache support as a UIImageView .... For iOS 5 and 6, use any 3.x version up to 3.7.6; For iOS < 5.0, please use the last 2.0 version. ... For details about how to use the library and clear examples,";
            [self setLineBreakMode:NSLineBreakByWordWrapping];
            self.backgroundColor = [UIColor clearColor];
            self.contentMode = UIViewContentModeLeft;
            self.textColor = [UIColor blackColor];
            [self setFont:[UIFont fontWithName:@"HelveticaNeue" size:16.0f]];
        }
        return self;
    }

@end


