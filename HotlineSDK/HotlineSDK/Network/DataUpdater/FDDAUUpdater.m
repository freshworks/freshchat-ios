//
//  FDDAUUpdater.m
//  HotlineSDK
//
//  Created by Hrishikesh on 14/05/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FDDAUUpdater.h"
#import "HLConstants.h"
#import "HLCoreServices.h"


@implementation FDDAUUpdater

-(id)init{
    self = [super init];
    if (self) {
        [self useInterval:DAU_UPDATE_INTERVAL];
        [self useConfigKey:HOTLINE_DEFAULTS_DAU_LAST_UPDATED_INTERVAL_TIME];
    }
    return self;
}

-(BOOL) canMakeDAUCall {
    NSDate *currentdate = [NSDate date];
    NSDate *lastFetchDate = [NSDate dateWithTimeIntervalSince1970:[[[FDSecureStore sharedInstance] objectForKey: HOTLINE_DEFAULTS_DAU_LAST_UPDATED_INTERVAL_TIME] doubleValue]/1000];
    NSCalendar* calendar = [NSCalendar currentCalendar];
    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSDateComponents* currentComp = [calendar components:unitFlags fromDate:currentdate];
    NSDateComponents* lastFetchComp = [calendar components:unitFlags fromDate:lastFetchDate];
    if (!([currentComp day] == [lastFetchComp day] && [currentComp month] == [lastFetchComp month] && [currentComp year]  == [lastFetchComp year])){
        return true;
    }
    return 0;
}

-(void)doFetch:(void(^)(NSError *error))completion{
    if([self canMakeDAUCall]){
        [HLCoreServices DAUCall:^(NSError *error) {
            if(completion){
                completion(error);
            }
        }];
    }
}
@end
