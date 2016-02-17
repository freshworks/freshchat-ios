//
//  FDBackgroundTaskManager.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 17/02/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FDBackgroundTaskManager : NSObject

+(instancetype)sharedInstance;

-(UIBackgroundTaskIdentifier)beginTask;

-(void)endTask:(UIBackgroundTaskIdentifier)taskID;

@end
