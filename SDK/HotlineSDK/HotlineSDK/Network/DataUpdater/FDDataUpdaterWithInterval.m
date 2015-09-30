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

@interface FDDataUpdaterWithInterval ()

-(NSDate *) lastFetchTime;

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

-(NSDate *) lastFetchTime{
    return [self.secureStore objectForKey:self.intervalConfigKey];
}

-(BOOL)hasTimedOut{
    NSDate *lastUpdatedTime = [self lastFetchTime];
    if (!lastUpdatedTime) return YES;
    NSDate *currentTime = [NSDate date];
    NSTimeInterval intervalInSeconds = [currentTime timeIntervalSinceDate:lastUpdatedTime];
    return (intervalInSeconds > self.intervalInSecs) ? YES : NO;
}

- (void) noUpdate
{
    // Hook for no update functionality
}

- (void)fetchWithCompletion:(void(^)(NSError *error))completion{
    if([self hasTimedOut]){
        [self doFetch:^(NSError * error) {
            if(!error){
                [self.secureStore setObject:[NSDate date] forKey:self.intervalConfigKey];
                FDLog("%@ Completed Update", [[self class] debugDescription]);
            }
            if(completion)completion(error);
        }];
    }
    else{
       FDLog("%@ Data still fresh . Not Updating", [[self class] debugDescription]);
       [self noUpdate];
       if (completion)
           completion(nil);
    }
}

- (void)fetch{
    [self fetchWithCompletion:nil];
}

- (void) doFetch:(void(^)(NSError *error))completion{ // Empty function .. Needs to be implemented by subclasses
    FDLog("WARNING : Unimplemented DoFetch For %@", [[self class] debugDescription]);
}

- (void) resetTime{
    [self.secureStore setObject:nil forKey:self.intervalConfigKey];
}

@end