//
//  FreshchatMessageObject.m
//  HotlineSDK
//
//  Created by user on 08/12/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "Freshchat.h"
#import <Foundation/Foundation.h>

@implementation FreshchatMessage

-(instancetype)initWithMessage:(NSString *)message andTag:(NSString *)tag{
    self = [super init];
    if (self) {
        self.message = message;
        self.tag = tag.lowercaseString;
    }
    return self;
}

@end
