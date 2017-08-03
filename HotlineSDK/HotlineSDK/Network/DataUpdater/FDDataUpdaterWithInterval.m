//
//  FDDataUpdaterWithInterval.m
//  FreshdeskSDK
//
//  Created by Hrishikesh on 06/11/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FDDataUpdaterWithInterval.h"
#import "HLMacros.h"

@interface FDDataUpdaterWithInterval()

@property (nonatomic        ) NSTimeInterval    intervalInSecs;
@property (nonatomic,strong ) NSString          *intervalConfigKey;
@property (strong, nonatomic) FDSecureStore     *secureStore;
@property (nonatomic)         NSTimeInterval    currentPollRequestTime;

@end

@implementation FDDataUpdaterWithInterval

#pragma mark - Lazy Instantiations

- (instancetype)init{
    self = [super init];
    if (self) {
        self.secureStore = [FDSecureStore sharedInstance];
    }
    return self;
}

- (void) useInterval:(long) interval{
    self.intervalInSecs = interval;
}

- (void) useConfigKey:(NSString *) configKey{
    self.intervalConfigKey = configKey;
}

-(NSTimeInterval) lastFetchTime{
    return [[self.secureStore objectForKey:self.intervalConfigKey] doubleValue];
}

-(BOOL)hasTimedOut{
    NSTimeInterval lastUpdatedTime = [self lastFetchTime];
    //Record the time at which the poller/update was requested
    self.currentPollRequestTime = ceil(([[NSDate date] timeIntervalSince1970]) * 1000);
    if (!lastUpdatedTime) return YES;
    
    FDLog(@"diff [%f] interval[%f]", (self.currentPollRequestTime-lastUpdatedTime) , self.intervalInSecs * 1000);
    if (ceil(self.currentPollRequestTime-lastUpdatedTime+1000)>=self.intervalInSecs * 1000) { // allow for a 1 second swing - 1000
        return YES;
    }else{
        return NO;
    }
}

- (void) noUpdate{
    // Hook for no update functionality
}

- (void)fetchWithCompletion:(void(^)(BOOL isFetchPerformed, NSError *error))completion{
    if([self hasTimedOut]){
        [self doFetch:^(NSError * error) {
            if(!error){
                // On slow network , the fetch can take about 3-4 secs.
                // use the time when the fetch started ( self.currentTime) instead of the completion time to avoid the time drift
                NSNumber *lastUpdatedTime = [NSNumber numberWithDouble:self.currentPollRequestTime];
                
                [self.secureStore setObject:lastUpdatedTime forKey:self.intervalConfigKey];
                FDLog("%@ Completed Update", [[self class] debugDescription]);
            }
            if(completion) completion(YES,error);
        }];
    }else{
        [self noUpdate];
        if (completion) completion(NO, nil);
        FDLog("%@ Data still fresh . Not Updating", [[self class] debugDescription]);
    }
}

- (void)fetch{
    [self fetchWithCompletion:nil];
}

- (void) doFetch:(void(^)(NSError *error))completion{
    FDLog("WARNING : Unimplemented DoFetch For %@", [[self class] debugDescription]);
}

- (void) resetTime{
    [self resetTimeTo:nil];
}

- (void) resetTimeTo:(NSNumber *) value {
    [self.secureStore setObject:value forKey:self.intervalConfigKey];
}

@end
