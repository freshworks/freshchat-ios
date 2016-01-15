//
//  HotlineAppState.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 29/12/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "HotlineAppState.h"

@implementation HotlineAppState

+(instancetype)sharedInstance{
    static HotlineAppState *sharedInstance = nil;
    static dispatch_once_t oncetoken;
    dispatch_once(&oncetoken,^{
        sharedInstance = [[HotlineAppState alloc]init];
    });
    return sharedInstance;
}



@end
