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
@property (nonatomic, strong) NSDictionary *properties;
@property (nonatomic, strong) NSString *eventName;
@property (nonatomic, strong) NSDictionary *eventDictionary;

@end

@implementation HLEvent

-(instancetype)initWithEventName:(NSString *)eventName andProperty :(NSDictionary *)properties{
    self = [super init];
    if (self) {
        self.properties = properties;
        self.eventName = eventName;
    }
    return self;
}

- (NSString *) getTracker{
    return [NSString stringWithFormat:@"HLiOS%@",[Hotline SDKVersion]];
}

-(void)saveEvent{
    self.eventDictionary = @{@"_tracker":[self getTracker],
                             @"_userId" :[FDUtilities getUserAlias],
                             @"_eventName":self.eventName,
                             @"_sessionId":[HLEventManager getUserSessionId],
                             @"_eventTimestamp":[NSNumber numberWithDouble:round([[NSDate date] timeIntervalSince1970]*1000)],
                             @"_properties":self.properties};
    [[HLEventManager sharedInstance] updateFileWithEvent:self.eventDictionary];
}

@end
