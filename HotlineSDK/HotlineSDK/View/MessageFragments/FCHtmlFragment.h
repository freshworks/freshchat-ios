//
//  FDHtmlFragment.h
//  HotlineSDK
//
//  Created by user on 07/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCMessageFragments.h"

enum ConvMessageType {
    AGENT  = 1,
    USER = 2
};

@interface FCHtmlFragment : UITextView

-(id) initFragment: (FragmentData *) fragment withFont :(UIFont *)font andType:(enum ConvMessageType) type;

@end
