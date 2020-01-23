//
//  FCEventsConfig.m
//  FreshchatSDK
//
//  Created by Harish kumar on 10/11/19.
//  Copyright © 2019 Freshdesk. All rights reserved.
//

#import "FCEventsConfig.h"
#import "FCUserDefaults.h"
#import "FCRefreshIntervals.h"

@implementation FCEventsConfig

- (instancetype)init{
    self = [super init];
    if (self) {
        self.maxDelayInMillisUntilUpload = [self getMaxDelayInMillisUntilUpload];
        self.maxEventsPerBatch = [self getMaxEventsPerBatch];
        self.maxAllowedEventsPerDay = [self getMaxAllowedEventsPerDay];
        self.maxAllowedPropertiesPerEvent = [self getMaxAllowedPropertiesPerEvent];
        self.triggerUploadOnEventsCount = [self getTriggerUploadOnEventsCount];
        
        self.maxCharsPerEventName = [self getMaxCharsPerEventName];
        self.maxCharsPerEventPropertyName = [self getMaxCharsPerEventPropertyName];
        self.maxCharsPerEventPropertyValue = [self getMaxCharsPerEventPropertyValue];
    }
    return self;
}

 - (int) getMaxAllowedEventsPerDay{
    if ([FCUserDefaults getObjectForKey:CONFIG_RC_EVENTS_MAX_ALLOWED_EVENTS_PER_DAY] != nil) {
        return [[FCUserDefaults getNumberForKey:CONFIG_RC_EVENTS_MAX_ALLOWED_EVENTS_PER_DAY] intValue];
    }
    return 50;
}

 - (int) getMaxEventsPerBatch{
    if ([FCUserDefaults getObjectForKey:CONFIG_RC_EVENTS_MAX_EVENTS_PER_BATCH] != nil) {
        return [[FCUserDefaults getNumberForKey:CONFIG_RC_EVENTS_MAX_EVENTS_PER_BATCH] intValue];
    }
    return 10;
}

- (int) getMaxAllowedPropertiesPerEvent{
    if ([FCUserDefaults getObjectForKey:CONFIG_RC_EVENTS_EVENT_MAX_ALLOWED_PROPERTIES_PER_EVENT] != nil) {
        return [[FCUserDefaults getObjectForKey:CONFIG_RC_EVENTS_EVENT_MAX_ALLOWED_PROPERTIES_PER_EVENT] intValue];
    }
    return 20;
}

- (int) getTriggerUploadOnEventsCount {
    if ([FCUserDefaults getObjectForKey:CONFIG_RC_EVENTS_TRIGGER_UPLOAD_ON_EVENTS_COUNT] != nil) {
        return [[FCUserDefaults getObjectForKey:CONFIG_RC_EVENTS_TRIGGER_UPLOAD_ON_EVENTS_COUNT] intValue];
    }
    return 5;
}

- (int) getMaxCharsPerEventName {
    if ([FCUserDefaults getObjectForKey:CONFIG_RC_EVENTS_MAX_CHARS_PER_EVENT_NAME] != nil) {
        return [[FCUserDefaults getObjectForKey:CONFIG_RC_EVENTS_MAX_CHARS_PER_EVENT_NAME] intValue];
    }
    return 32;
}

- (int) getMaxCharsPerEventPropertyName {
    if ([FCUserDefaults getObjectForKey:CONFIG_RC_EVENTS_MAX_CHARS_PER_EVENT_PROPERTY_NAME] != nil) {
        return [[FCUserDefaults getObjectForKey:CONFIG_RC_EVENTS_MAX_CHARS_PER_EVENT_PROPERTY_NAME] intValue];
    }
    return 32;
}

- (int) getMaxCharsPerEventPropertyValue {
    if ([FCUserDefaults getObjectForKey:CONFIG_RC_EVENTS_MAX_CHARS_PER_EVENT_PROPERTY_VALUE] != nil) {
        return [[FCUserDefaults getObjectForKey:CONFIG_RC_EVENTS_MAX_CHARS_PER_EVENT_PROPERTY_VALUE] intValue];
    }
    return 256;
}

 - (long) getMaxDelayInMillisUntilUpload{
    if ([FCUserDefaults getObjectForKey:CONFIG_RC_EVENTS_MAX_DELAY_IN_MILLIS_UNTIL_UPLOAD] != nil) {
        return [FCUserDefaults getLongForKey:CONFIG_RC_EVENTS_MAX_DELAY_IN_MILLIS_UNTIL_UPLOAD];
    }
    return (15 * ONE_SECONDS_IN_MS);
}

 - (void) updateEventsConfig : (NSDictionary *) info {
    [FCUserDefaults setNumber:info[@"maxAllowedEventsPerDay"] forKey:CONFIG_RC_EVENTS_MAX_ALLOWED_EVENTS_PER_DAY];
    [FCUserDefaults setNumber:info[@"maxEventsPerBatch"] forKey:CONFIG_RC_EVENTS_MAX_EVENTS_PER_BATCH];
    [FCUserDefaults setLong:[info[@"maxDelayInMillisUntilUpload"] longValue] forKey:CONFIG_RC_EVENTS_MAX_DELAY_IN_MILLIS_UNTIL_UPLOAD];
    [FCUserDefaults setNumber:info[@"maxAllowedPropertiesPerEvent"] forKey:CONFIG_RC_EVENTS_EVENT_MAX_ALLOWED_PROPERTIES_PER_EVENT];
    [FCUserDefaults setNumber:info[@"triggerUploadOnEventsCount"] forKey:CONFIG_RC_EVENTS_TRIGGER_UPLOAD_ON_EVENTS_COUNT];
    
    [FCUserDefaults setNumber:info[@"maxCharsPerEventName"] forKey:CONFIG_RC_EVENTS_MAX_CHARS_PER_EVENT_NAME];
    [FCUserDefaults setNumber:info[@"maxCharsPerEventPropertyName"] forKey:CONFIG_RC_EVENTS_MAX_CHARS_PER_EVENT_PROPERTY_NAME];
    [FCUserDefaults setNumber:info[@"maxCharsPerEventPropertyValue"] forKey:CONFIG_RC_EVENTS_MAX_CHARS_PER_EVENT_PROPERTY_VALUE];

}

@end
