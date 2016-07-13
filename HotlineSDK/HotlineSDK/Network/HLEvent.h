//
//  HLEvent.h
//  HotlineSDK
//
//  Created by Harish Kumar on 17/05/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface HLEvent : NSObject

-(instancetype)initWithEventName:(NSString *)eventName andProperty :(NSDictionary *)properties;

-(void)saveEvent;

@end
