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
        FDLog(@"bgtask trigger with ID %lu expired", (unsigned long)taskID);
        [application endBackgroundTask:taskID];
        taskID = UIBackgroundTaskInvalid;
    }];
    FDLog(@"bgtask trigger with ID %lu initiated", (unsigned long)taskID);
    return taskID;
}

-(void)endTask:(UIBackgroundTaskIdentifier)taskID{
    FDLog(@"bgtask task with ID %lu is ended", (unsigned long)taskID);
    [[UIApplication sharedApplication] endBackgroundTask:taskID];
}

@end