//
//  FDDateUtil.h
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 14/06/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDDateUtil : NSObject

+(NSString *)getRFC3339TimeStamp;
+(NSString *)getWebFriendlyTimeStamp;
+(NSDate *)getRFC3339DateFromString:(NSString *)dateString;
// Not used currently
//+(NSString *)itemCreatedDurationSinceDate:(NSDate*)date;
+(NSString *)solutionsLastUpdatedWebFriendlyTime;
+(NSString *)stringForUnixTime:(NSInteger)unixTime;
+(NSString *)getStringFromDate:(NSDate *)date;

@end
