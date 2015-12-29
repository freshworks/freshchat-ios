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

+(NSString *)getRFC3339TimeStamp{
    return [[FDDateUtil getDateFormatter] stringFromDate:[NSDate date]];
}

+(NSString *)getStringFromDate:(NSDate *)date{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"hh:mm a"];
    NSString *stringFromDate = [formatter stringFromDate:date];
    return stringFromDate;
}

+(NSDate *)getRFC3339DateFromString:(NSString *)pdateString{
    NSMutableString* dateString = [pdateString mutableCopy];
    NSRange range = [dateString rangeOfString:@":" options:NSBackwardsSearch];
    if (range.location != NSNotFound) {
        // remove the last ':'
        [dateString deleteCharactersInRange:range];
    }
    
    // Convert the RFC 3339 date time string to an NSDate.
    static NSDateFormatter* rfc3339DateFormatter1 = nil;
    static NSDateFormatter* rfc3339DateFormatter2 = nil;
    if (rfc3339DateFormatter1 == nil) {
        rfc3339DateFormatter1 = [[NSDateFormatter alloc] init];
        NSLocale* enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [rfc3339DateFormatter1 setLocale:enUSPOSIXLocale];
        [rfc3339DateFormatter1 setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZ"];
        [rfc3339DateFormatter1 setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        
        rfc3339DateFormatter2 = [[NSDateFormatter alloc] init];
        [rfc3339DateFormatter2 setLocale:enUSPOSIXLocale];
        [rfc3339DateFormatter2 setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"];
        [rfc3339DateFormatter2 setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    
    NSDate* date = [rfc3339DateFormatter1 dateFromString:dateString];
    if (date == nil) {
        date = [rfc3339DateFormatter2 dateFromString:dateString];
    }
    
    return date;
}

// Not used currently
// Add in the Localization when used . - Rex
//+(NSString *)itemCreatedDurationSinceDate:(NSDate*)date{
//    NSInteger FEW_SECONDS = 50;
//    NSInteger FEW_MINUTES = 5, ONE_HOUR = 60, ONE_DAY = 1440, ONE_MONTH = 43200;    //(in minutes)
//    NSTimeInterval intervalInSeconds = [[NSDate date] timeIntervalSinceDate:date];
//    NSInteger interval = intervalInSeconds/60;
//    if (intervalInSeconds < 10) {
//        return HLLocalizedString(@"Just now");
//    }else if(intervalInSeconds < FEW_SECONDS){
//        return HLLocalizedString(@"few seconds ago");
//    }else if (interval < FEW_MINUTES) {
//        return HLLocalizedString(@"few minutes ago");
//    }else if(interval >= FEW_MINUTES && interval < ONE_HOUR){
//        return [NSString stringWithFormat:HLLocalizedString(@"n minutes ago"),(long)interval];
//    }else if(interval >= ONE_HOUR && interval < ONE_DAY){
//        NSInteger hours = (int)interval/ONE_HOUR;
//        if (hours == 1) { return HLLocalizedString(@"an hour ago"); }
//        return [NSString stringWithFormat:HLLocalizedString(@"n hours ago"),(long)hours];
//    }else if(interval >=ONE_DAY && interval< ONE_MONTH){
//        NSInteger days = (int)interval/ONE_DAY;
//        if (days == 1) { return HLLocalizedString(@"a day ago"); }
//        return [NSString stringWithFormat:HLLocalizedString(@"n days ago"),(long)days];
//    }else{
//        return HLLocalizedString(@"more than a month ago");
//    }
//}

+(NSString *)stringForUnixTime:(NSInteger)unixTime{
    NSTimeInterval interval = unixTime;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
    NSDateFormatter *formatter=[[NSDateFormatter alloc]init];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [formatter stringFromDate:date];
}

+(NSString *)solutionsLastUpdatedWebFriendlyTime{
    FDSecureStore *secureStore = [FDSecureStore sharedInstance];
    NSDate *lastUpdatedTime = [secureStore objectForKey:HOTLINE_DEFAULTS_SOLUTIONS_LAST_UPDATED_TIME];
    NSString *lastUpdatedTimeString = [[FDDateUtil getDateFormatter] stringFromDate:lastUpdatedTime];
//    return [lastUpdatedTimeString stringByReplacingOccurrencesOfString:@"+0000" withString:@"%2B00:00"];
    return lastUpdatedTimeString;
}

+(NSString *)getWebFriendlyTimeStamp{
    NSString *timeStamp = [self getRFC3339TimeStamp];
    return timeStamp;
}


@end