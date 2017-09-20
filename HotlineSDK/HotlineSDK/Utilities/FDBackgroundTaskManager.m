//
//  FDBackgroundTaskManager.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 17/02/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FDBackgroundTaskManager.h"
#import "HLMacros.h"

@implementation FDBackgroundTaskManager

+(instancetype)sharedInstance{
    static FDBackgroundTaskManager *fdBackgroundTaskManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fdBackgroundTaskManager = [[self alloc]init];
    });
    return fdBackgroundTaskManager;
}

- (UIBackgroundTaskIdentifier)beginTask{
    UIApplication *application = [UIApplication sharedApplication];
    __block NSUInteger taskID = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:taskID];
        taskID = UIBackgroundTaskInvalid;
    }];
    return taskID;
}

-(void)endTask:(UIBackgroundTaskIdentifier)taskID{
    [[UIApplication sharedApplication] endBackgroundTask:taskID];
}

@end
