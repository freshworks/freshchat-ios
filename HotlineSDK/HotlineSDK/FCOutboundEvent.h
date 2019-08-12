//
//  FCOutboundEvent.h
//  FreshchatSDK
//
//  Created by Harish Kumar on 13/05/19.
//  Copyright © 2019 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FreshchatSDK.h"


@interface FCOutboundEvent : NSObject

@property (nonatomic, assign) FCEvent eventName;

@property (strong, nonatomic) NSDictionary *properties;

- (instancetype) initOutboundEvent :(FCEvent) eventName withParams : (NSDictionary*) properties;

@end
