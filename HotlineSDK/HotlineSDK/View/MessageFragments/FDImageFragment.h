//
//  FDImageFragment.h
//  HotlineSDK
//
//  Created by user on 07/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Fragment.h"
#import "HLAgentMessageCell.h"
#import "HLUserMessageCell.h"
#import "FCTheme.h"

@interface FDImageFragment : UIImageView
    -(id) initWithFragment: (FragmentData *) fragment ofMessage:(MessageData*)message;
    @property (nonatomic, weak) id<HLMessageCellDelegate> agentMessageDelegate;
    @property (nonatomic, weak) id<HLUserMessageCellDelegate> userMessageDelegate;
    @property CGRect imgFrame;
    @property FragmentData *fragmentData;
@end
