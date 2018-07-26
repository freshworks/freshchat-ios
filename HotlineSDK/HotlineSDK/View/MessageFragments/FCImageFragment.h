//
//  FDImageFragment.h
//  HotlineSDK
//
//  Created by user on 07/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCAgentMessageCell.h"
#import "FCUserMessageCell.h"
#import "FCMessageFragments.h"
#import "FCTheme.h"

@interface FCImageFragment : UIImageView
    -(id) initWithFragment: (FragmentData *) fragment ofMessage:(FCMessageData*)message;
    @property (nonatomic, weak) id<HLMessageCellDelegate> delegate;
    @property CGRect imgFrame;
    @property FragmentData *fragmentData;
@end
