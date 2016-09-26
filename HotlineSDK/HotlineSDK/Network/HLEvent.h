//
//  HLEvent.h
//  HotlineSDK
//
//  Created by Harish Kumar on 17/05/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface HLEvent : NSObject

-(instancetype)initWithEventName:(NSString *)eventName;

-(HLEvent *) propKey:(NSString *) key andVal:(NSString *) value;

-(void)saveEvent;

@end
