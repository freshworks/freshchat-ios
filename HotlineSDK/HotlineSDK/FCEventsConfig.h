//
//  FCEventsConfig.h
//  FreshchatSDK
//
//  Created by Harish kumar on 10/11/19.
//  Copyright © 2019 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FCEventsConfig : NSObject

@property (nonatomic, assign) long maxDelayInMillisUntilUpload;
@property (nonatomic, assign) int maxEventsPerBatch;
@property (nonatomic, assign) int maxAllowedEventsPerDay;
@property (nonatomic, assign) int maxAllowedPropertiesPerEvent;
@property (nonatomic, assign) int triggerUploadOnEventsCount;

@property (nonatomic, assign) int maxCharsPerEventName;
@property (nonatomic, assign) int maxCharsPerEventPropertyName;
@property (nonatomic, assign) int maxCharsPerEventPropertyValue;


 - (void) updateEventsConfig : (NSDictionary *) info;

@end
