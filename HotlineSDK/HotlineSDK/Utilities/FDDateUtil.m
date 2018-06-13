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
#import "FDLocaleUtil.h"

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

+ (NSDateFormatter *) getDateFormatter: (bool) includeDate {
    NSLocale *locale =[[NSLocale alloc] initWithLocaleIdentifier:[FDLocaleUtil getUserLocale]];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:locale];
    if(includeDate) {
        [dateFormatter setDateFormat:@"MMM dd, hh:mm a"];
    } else {
        [dateFormatter setDateFormat:@"hh:mm a"];
    }
    return dateFormatter;
}

+(NSString*) stringRepresentationForDate:(NSDate*) dateToDisplay {
    NSDate* today=[[NSDate alloc] init];
    NSDateFormatter *dateFormatter;
    
    NSDateComponents *componentsToday = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:today];
    NSDateComponents *componentsForDateToDisplay = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:dateToDisplay];
    NSInteger todayDate = [componentsToday day];
    NSInteger datetoDisplayDate = [componentsForDateToDisplay day];
    
    if (todayDate == datetoDisplayDate) {
        dateFormatter = [self getDateFormatter:false];
    } else {
        dateFormatter = [self getDateFormatter:true];
    }
    NSString* timeString = [dateFormatter stringFromDate:dateToDisplay];
    return timeString;
}

+(NSNumber *) maxDateOfNumber:(NSNumber *) lastUpdatedTime andStr:(NSString*) lastUpdatedStr{
    NSNumber *lastUpdatedStrVal = [NSNumber numberWithDouble:[lastUpdatedStr doubleValue]];
    if([lastUpdatedTime compare:lastUpdatedStrVal] != NSOrderedDescending){
        return lastUpdatedStrVal;
    }
    return lastUpdatedTime;
}

@end
