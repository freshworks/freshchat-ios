//
//  FDDateUtil.h
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 14/06/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FCDateUtil : NSObject

+(NSString*) stringRepresentationForDate:(NSDate*) dateToDisplay;
+(NSString*) stringRepresentationForDate:(NSDate*) dateToDisplay includeTimeForCurrentYear : (BOOL)includeTimeForCurrentYear;
+(NSNumber *) maxDateOfNumber:(NSNumber *) lastUpdatedTime andStr:(NSString*) lastUpdatedStr;

@end
