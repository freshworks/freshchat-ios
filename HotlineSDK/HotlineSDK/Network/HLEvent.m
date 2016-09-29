//
//  HLUserEvent.m
//  HotlineSDK
//
//  Created by Harish Kumar on 17/05/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "HLEvent.h"
#import "HLEventManager.h"
#import "Hotline.h"
#import "FDUtilities.h"

@interface HLEvent()
@property (nonatomic, strong) NSMutableDictionary *properties;
@property (nonatomic, strong) NSString *eventName;

@end

@implementation HLEvent

-(instancetype)initWithEventName:(NSString *)eventName{
    self = [super init];
    if (self) {
        self.properties = [NSMutableDictionary new];
        self.eventName = eventName;
    }
    return self;
}

-(HLEvent *) event:(NSString *)eventName {
    return self;
}

-(HLEvent *) propKey:(NSString *) key andVal:(NSString *) value {
    if(key && value){
        [self.properties setObject:value forKey:key];
    }
    return self;
}

-(void)saveEvent{
    if([FDUtilities getUserAlias] && [Hotline sharedInstance].config.appID && [FDUtilities getTracker]) {
        NSDictionary *eventDictionary = @{@"_tracker":[FDUtilities getTracker],
                                          @"_userId" :[FDUtilities getUserAlias],
                                          @"_eventName":self.eventName,
                                          @"_sessionId":[HLEventManager getUserSessionId],
                                          @"_eventTimestamp":[NSNumber numberWithDouble:round([[NSDate date] timeIntervalSince1970]*1000)],
                                          @"_appId" : [Hotline sharedInstance].config.appID,
                                          @"_properties":self.properties};
        [[HLEventManager sharedInstance] updateFileWithEvent:eventDictionary];
    }
}

@end
