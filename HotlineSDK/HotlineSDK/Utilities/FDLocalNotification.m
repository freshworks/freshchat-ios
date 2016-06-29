//
//  FDLocalNotification.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 27/06/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FDLocalNotification.h"

@implementation FDLocalNotification

+(void)post:(NSString *)name{
    [self post:name sender:nil info:nil];
}

+(void)post:(NSString *)name info:(id)info{
    [self post:name sender:nil info:info];
}

+(void)post:(NSString *)name sender:(id)sender info:(id)info{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:name object:sender userInfo:info];
    });
}

@end