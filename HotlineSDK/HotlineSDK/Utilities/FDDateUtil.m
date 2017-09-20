//
//  FDDateUtil.m
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 14/06/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDDateUtil.h"
#import "FDSecureStore.h"
#import "HLMacros.h"

@implementation FDDateUtil

+(NSDateFormatter *)getDateFormatter{
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter            = [[NSDateFormatter alloc]init];
        NSLocale *en_US_POSIX     = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.locale     = en_US_POSIX;
        dateFormatter.timeZone   = [NSTimeZone timeZoneForSecondsFromGMT:0];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    });
    return dateFormatter;
}

+(NSString *)getStringFromDate:(NSDate *)date{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"hh:mm a"];
    NSString *stringFromDate = [formatter stringFromDate:date];
    return stringFromDate;
}

+(NSNumber *) maxDateOfNumber:(NSNumber *) lastUpdatedTime andStr:(NSString*) lastUpdatedStr{
    NSNumber *lastUpdatedStrVal = [NSNumber numberWithDouble:[lastUpdatedStr doubleValue]];
    if([lastUpdatedTime compare:lastUpdatedStrVal] != NSOrderedDescending){
        return lastUpdatedStrVal;
    }
    return lastUpdatedTime;
}

@end