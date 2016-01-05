//
//  FDUtilities.h
//  FreshdeskSDK
//
//  Created by balaji on 15/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#ifndef FreshdeskSDK_FDUtilities_h
#define FreshdeskSDK_FDUtilities_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FDUtilities : NSObject

+(NSString *)getUserAlias;
+(NSString *)generateUUID;
+(void)storeUserAlias:(NSString *)alias;
+(BOOL)isUserRegistered;

+(NSString *)base64EncodedStringFromString:(NSString *)string;
+(NSString *)sanitizeStringForUTF8:(NSString *)string;
+(NSString *)sanitizeStringForNewLineCharacter:(NSString *)string;
+(NSString *)replaceSpecialCharacters:(NSString *)term with:(NSString *)replaceString;
+(void)assertMainThread;
+(UIImage *)imageWithColor:(UIColor *)color;
+(NSString*)stringRepresentationForDate:(NSDate*) date;
+(NSString *) getKeyForObject:(NSObject *) object;
+(NSString *)getAdID;
+(NSString *)generateOfflineMessageAlias;

@end

#endif