//
//  FDReachabilityManager.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 07/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDReachabilityManager.h"
#import "FDReachability.h"
#import "FDLocalNotification.h"

@interface FDReachabilityManager ()

@property (nonatomic, strong) FDReachability *reachability;

@end

@implementation FDReachabilityManager

-(instancetype)initWithDomain:(NSString *)domain{
    self = [super init];
    if (self) {
        self.reachability = [FDReachability reachabilityWithHostname:domain];
        __weak typeof(self)weakSelf = self;
        self.reachability.reachableBlock = ^(FDReachability*reach){
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter]postNotificationName:HOTLINE_NETWORK_REACHABLE object:weakSelf];
            });
        };
        
        self.reachability.unreachableBlock = ^(FDReachability *reach){
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter]postNotificationName:HOTLINE_NETWORK_UNREACHABLE object:weakSelf];
            });
        };
    }
    return self;
    
}

-(void)start{
    [self.reachability startNotifier];
}

@end