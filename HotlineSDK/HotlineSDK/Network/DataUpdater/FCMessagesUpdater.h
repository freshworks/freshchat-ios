//
//  FDMessagesUpdater.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 27/04/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCDataUpdaterWithInterval.h"

@interface FCMessagesUpdater : FCDataUpdaterWithInterval

@property (nonatomic) enum MessageRequestSource requestSource;

@end
