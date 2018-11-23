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

+(void) launchChannelWithTags:(NSArray *)tags withNavigationCtlr:(UIViewController *)viewController;

+(void) launchChannelWithId:(NSNumber *)channelID withNavigationCtlr:(UIViewController *)viewController;

@end
