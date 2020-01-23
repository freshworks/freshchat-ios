//
//  FCEventsManager.h
//  FreshchatSDK
//
//  Created by Harish kumar on 10/11/19.
//  Copyright © 2019 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FCEventsManager : NSObject

+ (instancetype)sharedInstance;

-(void) submitSDKEventWithInfo:(NSDictionary *) eventInfo;

-(void)startEventsUploadTimer;

-(void) processEventBatch;

-(void) reset;

@end

