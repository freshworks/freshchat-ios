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

@implementation FDDataUpdaterWithInterval

#pragma mark - Lazy Instantiations

- (instancetype)init{
    self = [super init];
    if (self) {
        self.secureStore = [FDSecureStore sharedInstance];
    }
    return self;
}

-(NSTimeInterval) lastFetchTime{
    return [[self.secureStore objectForKey:self.intervalConfigKey]doubleValue];
}

//TODO: when migrating mobihelp -> hotline, clear intervalconfigkey from secure store
-(BOOL)hasTimedOut{
    NSTimeInterval lastUpdatedTime = [self lastFetchTime];
    if (!lastUpdatedTime) return YES;
    NSTimeInterval currentTime = round([[NSDate date] timeIntervalSince1970]*1000);
    if ((currentTime-lastUpdatedTime)>self.intervalInSecs * 1000) {
        return YES;
    }else{
        return NO;
    }
}

- (void) noUpdate
{
    // Hook for no update functionality
}

- (void)fetchWithCompletion:(void(^)(BOOL isFetchPerformed, NSError *error))completion{
    if([self hasTimedOut]){
        [self doFetch:^(NSError * error) {
            if(!error){
                [self.secureStore setObject:[NSDate date] forKey:self.intervalConfigKey];
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

- (void) doFetch:(void(^)(NSError *error))completion{ // Empty function .. Needs to be implemented by subclasses
    FDLog("WARNING : Unimplemented DoFetch For %@", [[self class] debugDescription]);
}

- (void) resetTime{
    [self.secureStore setObject:nil forKey:self.intervalConfigKey];
}

@end