//
//  FDDateUtil.m
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 14/06/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FCDateUtil.h"
#import "FCSecureStore.h"
#import "FCMacros.h"
#import "FCLocaleUtil.h"
#import "FCLocalization.h"

@implementation FCDateUtil

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

+(NSString*) stringRepresentationForDate:(NSDate*) dateToDisplay {
    return [FCDateUtil stringRepresentationForDate:dateToDisplay includeTimeForCurrentYear:YES];
}

+(NSString*) stringRepresentationForDate:(NSDate*) dateToDisplay includeTimeForCurrentYear : (BOOL)includeTimeForCurrentYear {
    NSDate* today=[[NSDate alloc] init];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    NSDateComponents *componentsToday = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:today];
    NSDateComponents *componentsForDateToDisplay = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:dateToDisplay];
    
    NSInteger currentDay = [componentsToday day];
    NSInteger dayToDisplay = [componentsForDateToDisplay day];
    
    NSInteger currentMonth = [componentsToday month];
    NSInteger monthToDisplay = [componentsForDateToDisplay month];
    
    NSInteger currentYear = [componentsToday year];
    NSInteger yearToDisplay = [componentsForDateToDisplay year];
    
    NSLocale *locale =[[NSLocale alloc] initWithLocaleIdentifier:[FCLocaleUtil getUserLocale]];
    [dateFormatter setLocale:locale];
    if ((currentDay == dayToDisplay) && (currentYear == yearToDisplay) && (currentMonth == monthToDisplay)){
        [dateFormatter setDateFormat:HLLocalizedString(LOC_CHAT_MESSAGE_TIME_TODAY)];
    }else if(currentYear == yearToDisplay){
        [dateFormatter setDateFormat:includeTimeForCurrentYear ? HLLocalizedString(LOC_CHAT_MESSAGE_TIME_THIS_YEAR_LONG) : HLLocalizedString(LOC_CHAT_MESSAGE_TIME_THIS_YEAR_SHORT)];
    }else{
        [dateFormatter setDateFormat:HLLocalizedString(LOC_CHAT_MESSAGE_TIME_OTHER_YEAR)];
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
