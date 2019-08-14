//
//  FreshchatEvent.m
//  FreshchatSDK
//
//  Created by Harish Kumar on 16/04/19.
//  Copyright © 2019 Freshdesk. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "FCEventsHelper.h"
#import "FCOutboundEvent.h"

@interface  FreshchatEvent()

@end

@implementation FreshchatEvent

@synthesize name;
@synthesize properties;

-(instancetype)init{
    self = [super init];
    return self;
}

- (id) valueForEventProperty : (FCEventProperty) property {
    return [self.properties
            objectForKey:[[FCEventsHelper getEventsDict] objectForKey:@(property)]];
}

@end
