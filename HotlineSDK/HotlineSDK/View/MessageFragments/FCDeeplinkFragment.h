//
//  FDDeeplinkFragment.h
//  HotlineSDK
//
//  Created by user on 09/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FCMessageFragments.h"
#import "FCAgentMessageCell.h"
#import "FCUserMessageCell.h"

@interface FCDeeplinkFragment : UIButton
    -(id) initWithFragment: (FragmentData *) fragment;
    @property (nonatomic, weak) id<HLMessageCellDelegate> delegate;
    @property FragmentData *fragmentData;
@end
