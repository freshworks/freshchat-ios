//
//  FCChannelUtil.h
//  HotlineSDK
//
//  Created by Sanjith Kanagavel on 20/11/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCFAQUtil.h"

@interface FCChannelUtil : NSObject

+(void) launchChannelWithTags:(NSArray *)tags withTitle:(NSString *)title withNavigationCtlr:(UIViewController *)viewController;

+(void) launchChannelWithId:(NSNumber *)channelID withTitle:(NSString *)title withNavigationCtlr:(UIViewController *)viewController;

@end
