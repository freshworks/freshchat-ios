//
//  FCUnknownFragment.h
//  FreshchatSDK
//
//  Created by Harish Kumar on 05/09/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FCMessageFragments.h"
#import "FCAgentMessageCell.h"
#import "FCUserMessageCell.h"

@interface FCUnsupportedFragment : UIView

-(id) initWithFragment: (FragmentData *) fragment;
@property FragmentData *fragmentData;

@end
