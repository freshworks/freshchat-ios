//
//  FDReachabilityManager.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 07/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FCReachabilityManager.h"
#import "FCReachability.h"
#import "FCLocalNotification.h"

@interface FCReachabilityManager ()

@property (nonatomic, strong) FCReachability *reachability;

@end

@implementation FCReachabilityManager

-(instancetype)initWithDomain:(NSString *)domain{
    self = [super init];
    if (self) {
        self.reachability = [FCReachability reachabilityForInternetConnection];
        __weak typeof(self)weakSelf = self;
        self.reachability.reachableBlock = ^(FCReachability*reach){
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter]postNotificationName:HOTLINE_NETWORK_REACHABLE object:weakSelf];
            });
        };
        
        self.reachability.unreachableBlock = ^(FCReachability *reach){
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

-(BOOL)isReachable{
    return ([self.reachability currentReachabilityStatus] != NotReachable);
}

+(instancetype)sharedInstance{
    static FCReachabilityManager *fdReachabilityManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fdReachabilityManager = [[FCReachabilityManager alloc]initWithDomain:@"https://www.google.com"];
    });
    return fdReachabilityManager;
}

@end
