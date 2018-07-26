//
//  FCCSATUtil.h
//  FreshchatSDK
//
//  Created by Harish Kumar on 24/07/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCCsat.h"

@interface FCCSATUtil : NSObject

+ (BOOL) isCSATExpiredForInitiatedTime : (long)initiatedTime;
+ (void) deleteExpiredCSAT;
+ (void) deleteCSATAndUpdateConversation : (FCCsat *) csat;

@end
