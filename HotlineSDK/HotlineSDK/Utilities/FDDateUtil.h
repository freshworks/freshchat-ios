//
//  FDDateUtil.h
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 14/06/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDDateUtil : NSObject

+(NSString*) stringRepresentationForDate:(NSDate*) dateToDisplay;
+(NSNumber *) maxDateOfNumber:(NSNumber *) lastUpdatedTime andStr:(NSString*) lastUpdatedStr;

@end
