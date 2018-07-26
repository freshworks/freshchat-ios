//
//  FDVideoFragment.h
//  HotlineSDK
//
//  Created by user on 07/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"
#import "FCMessageFragments.h"

@interface FCVideoFragment: UIButton
    -(id) initWithFragment: (FragmentData *) fragment;
    @property FragmentData *fragmentData;
@end
