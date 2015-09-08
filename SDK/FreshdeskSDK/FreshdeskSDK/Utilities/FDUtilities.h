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
#import "FDTicketContent.h"
#import "Mobihelp.h"
#import <UIKit/UIKit.h>

@interface FDUtilities : NSObject

//User Info
+(BOOL)isRegisteredUser;
+(NSString *)getUserName;
+(NSString *)getEmailAddress;
+(NSString *)getUUID;
+(BOOL)isSSLEnabled;
+(BOOL)isFirstLaunch;
+(FEEDBACK_TYPE)getFeedBackType;

//App Review Request
+(BOOL)metReviewRequestCycle;
+(BOOL)hasUserPreferredAppReview;
+(void)stopFurtherReviewRequest;

//Registration Information
+(NSDictionary *)getRegistrationInformation;
+(NSDictionary *)getTicketInfoWithContent:(FDTicketContent *)content;
+(void)getDeviceAppInfoCompletionHandler:(void(^)(NSData *data))completion;

//Utilities
+(UIColor *)colorWithHex:(NSString *)value;
+(void)incrementLaunchCount;
+(BOOL)isValidEmail:(NSString *)email;
+(NSString *)base64EncodedStringFromString:(NSString *)string;
+(NSString *)sanitizeStringForUTF8:(NSString *)string;
+(NSString *)sanitizeStringForNewLineCharacter:(NSString *)string;
+(NSString *)replaceSpecialCharacters:(NSString *)term with:(NSString *)replaceString;
+(void)assertMainThread;
+(UIImage *)imageWithColor:(UIColor *)color;

@end

#endif