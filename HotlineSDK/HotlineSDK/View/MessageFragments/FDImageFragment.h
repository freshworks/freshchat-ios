//
//  FDImageFragment.h
//  HotlineSDK
//
//  Created by user on 07/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Fragment.h"
#import "HLMessageCell.h"
#import "HLTheme.h"

@interface FDImageFragment : UIImageView
    -(id) initWithFragment: (FragmentData *) fragment ofMessage:(MessageData*)message;
    @property (nonatomic, weak) id<HLMessageCellDelegate> delegate;
    @property CGRect imgFrame;
    @property FragmentData *fragmentData;
@end
