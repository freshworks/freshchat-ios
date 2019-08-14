//
//  FCInboundEvents.m
//  FreshchatSDK
//
//  Created by Harish Kumar on 13/05/19.
//  Copyright © 2019 Freshdesk. All rights reserved.
//

#import "FCOutboundEvent.h"
#import "FCEventsHelper.h"


@implementation FCOutboundEvent

- (instancetype) initOutboundEvent :(FCEvent) eventName withParams : (NSDictionary*) properties {
    
    self = [super init];
    if (self) {
        
        self.eventName = eventName;
        
        if(properties && (properties.count > 0)){
            self.properties = [FCEventsHelper getDictionaryForParamsDict:properties];
        }
    }
    return self;
}

@end
