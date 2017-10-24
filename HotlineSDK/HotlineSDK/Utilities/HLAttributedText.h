//
//  HLAttributedText.h
//  HotlineSDK
//
//  Created by user on 01/08/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "Foundation/Foundation.h"
#import "UIKit/UIKit.h"

@interface HLAttributedText : NSObject

    + (instancetype)sharedInstance;

    -(NSMutableAttributedString *) getAttributedString:(NSString *)string ;
    -(NSMutableAttributedString *) addAttributedString:(NSString *)string withFont:(UIFont*) font;

@end
