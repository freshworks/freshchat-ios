//
//  FDUtilities.m
//  FreshdeskSDK
//
//  Created by balaji on 15/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <asl.h>
#import "FDNetworking.h"
#import "FDUtilities.h"
#import "FDAPIClient.h"
#import "FDBreadCrumb.h"
#import "FDCustomData.h"
#import "FDBaseQueue.h"
#import "FDDateUtil.h"
#import "FDSecureStore.h"
#import "Mobihelp.h"
#import "FDDeviceInfo.h"
#import "FDMacros.h"
#import "FDConstants.h"
#import "FDQueue.h"

@implementation FDUtilities

#pragma mark - Device and user registration information

+(NSDictionary *)getRegistrationInformation{
    NSDictionary *registrationInfo = @{
               @"user":[self getUserInformation],
               @"device_info":@{
                       @"device_uuid" : [self getUUID],
                       @"make" : [FDDeviceInfo deviceMake],
                       @"model" : [FDDeviceInfo deviceModelName],
                       @"platform" : @"IOS",
                       @"os_ver" : [FDDeviceInfo osVersion],
                       @"app_ver": [FDDeviceInfo appVersion]
                       }
               };
    return registrationInfo;
}

+(NSDictionary *)getUserInformation{
    NSMutableDictionary *userInformation = [[NSMutableDictionary alloc]init];
    NSString *storedUserName     = [self getUserName];
    NSString *storedEmailAddress = [self getEmailAddress];
    FDSecureStore *secureStore = [FDSecureStore sharedInstance];
    FEEDBACK_TYPE feedbackType = [secureStore intValueForKey:MOBIHELP_DEFAULTS_APP_FEEDBACK_TYPE];
    if (feedbackType == FEEDBACK_TYPE_ANONYMOUS) {
        storedUserName = FDLocalizedString(@"Default User Name");
        [userInformation setObject:storedUserName forKey:@"name"];
    } else {
        if (storedUserName && trimString(storedUserName).length > 0) {
            [userInformation setObject:storedUserName forKey:@"name"];
        }
        if (storedEmailAddress && trimString(storedEmailAddress).length > 0 && [self isValidEmail:storedEmailAddress]){
            [userInformation setObject:storedEmailAddress forKey:@"email"];
        }
    }
    [userInformation setObject:[self getUUID] forKey:@"external_id"];
    return userInformation;
}

+(NSString *)getUserName{
    FDSecureStore *secureStore = [FDSecureStore sharedInstance];
    BOOL isUserNameExist = [secureStore checkItemWithKey:MOBIHELP_DEFAULTS_USER_NAME];
    if (isUserNameExist) {
        return [secureStore objectForKey:MOBIHELP_DEFAULTS_USER_NAME];
    }else{
        return nil;
    }
}

+(NSString *)getEmailAddress{
    FDSecureStore *secureStore = [FDSecureStore sharedInstance];
    BOOL isEmailExist = [secureStore checkItemWithKey:MOBIHELP_DEFAULTS_USER_EMAIL_ADDRESS];
    if (isEmailExist) {
        return [secureStore objectForKey:MOBIHELP_DEFAULTS_USER_EMAIL_ADDRESS];
    }else{
        return nil;
    }
}

+(BOOL)isRegisteredUser{
    FDSecureStore *secureStore = [FDSecureStore sharedInstance];
    BOOL apiKeyPresent = [secureStore checkItemWithKey:MOBIHELP_DEFAULTS_API_KEY];
    if(apiKeyPresent && [secureStore boolValueForKey:MOBIHELP_DEFAULTS_USER_REGISTRATION_STATUS]){
        return true;
    }// make sure apiKey is present
    return false;
}

+(BOOL)isValidEmail:(NSString *)email{
    NSString *emailPattern=@"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,15}";
    NSPredicate *emailPatternPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",emailPattern];
    return ([emailPatternPredicate evaluateWithObject:email]) ? YES : NO;
}

+(BOOL)isSSLEnabled{
    FDSecureStore *secureStore = [FDSecureStore sharedInstance];
    BOOL isSSLInfoExist = [secureStore checkItemWithKey:MOBIHELP_DEFAULTS_IS_SSL_ENABLED];
    if (isSSLInfoExist) {
        return [secureStore boolValueForKey:MOBIHELP_DEFAULTS_IS_SSL_ENABLED];
    }else{
        return YES;
    }
}

+(BOOL)isFirstLaunch{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"FD_MOBIHELP_IS_FIRST_LAUNCH"]) {
        return NO;
    }else{
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"FD_MOBIHELP_IS_FIRST_LAUNCH"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return YES;
    }
}

+(NSDictionary *)getTicketInfoWithContent:(FDTicketContent *)content{
    NSDictionary *ticketInfo = @{
        @"helpdesk_ticket":@{
            @"source"       : @"8",
            @"subject"      : content.ticketSubject,
            @"external_id"  : [FDUtilities getUUID],
            @"ticket_body_attributes" : @{
                @"description" : content.ticketBody
                },
            @"mobihelp_ticket_info_attributes" : @{
                @"app_name"     : [FDDeviceInfo appName],
                @"app_version"  : [FDDeviceInfo appVersion],
                @"os"           : [FDDeviceInfo osName],
                @"os_version"   : [FDDeviceInfo osVersion],
                @"device_make"  : [FDDeviceInfo deviceMake],
                @"device_model" : [FDDeviceInfo deviceModelName],
                @"sdk_version"  : [FDDeviceInfo mobihelpSDKVersion],
                }
            }
        };
    return ticketInfo;
}

#pragma mark - Debug Log collection

+ (NSString *)getDebugLog {
    //Debug Log Configurations
    const char *appIdentifier = [[FDDeviceInfo appIdentifier]UTF8String];
    FDQueue *logs = [[FDQueue alloc]initWithSize:MOBIHELP_CONSTANTS_LOG_COUNT_LIMIT];
    NSMutableDictionary *tmpDict;
    //Other variables
    int i;
    aslmsg query,message;
    const char *key, *value;
    query = asl_new(ASL_TYPE_QUERY);
    asl_set_query (query, ASL_KEY_FACILITY, appIdentifier, ASL_QUERY_OP_EQUAL);
    aslresponse r = asl_search(NULL, query);
    while (NULL != (message = aslresponse_next(r))){
        tmpDict = [NSMutableDictionary dictionary];
        for (i = 0; (NULL != (key = asl_key(message, i))); i++){
            NSString *keyString = [NSString stringWithUTF8String:(char *)key];
            value = asl_get(message, key);
            NSString *valueString = value?[NSString stringWithUTF8String:value]:@"";
            if (keyString && valueString) { tmpDict[keyString]=valueString; }
        }
        [logs enqueue:tmpDict];
    }
    aslresponse_free(r);
    return [self parseDebugLogWithLogs:[logs contentsAsArray]];
}

+(NSString *)parseDebugLogWithLogs:(NSArray *)logs{
    NSString *debugLog = @"\n";
    for (NSInteger i=0; i<[logs count]; i++) {
        NSDictionary *log        = logs[i];
        NSInteger unixTime       = [[log valueForKey:@"Time"]integerValue];
        NSString *unixTimeString = [FDDateUtil stringForUnixTime:unixTime];
        NSString *message        = [log valueForKey:@"Message"];
        NSString *logMeta        = [NSString stringWithFormat:@"%@", unixTimeString];
        debugLog                 = [debugLog stringByAppendingString:logMeta];
        NSString *logMessage     = [NSString stringWithFormat:@" %@\n\n",message];
        debugLog                 = [debugLog stringByAppendingString:logMessage];
    }
    return debugLog;
}

#pragma mark - Collecting Device Infomation

+(void)getDeviceAppInfoCompletionHandler:(void(^)(NSData *data))completion{
    dispatch_queue_t myPrivateQueue = dispatch_queue_create("DebugLogQueue", NULL);
    dispatch_async(myPrivateQueue, ^{
        NSDictionary *deviceAppInfo = @{
                                @"app_info"     : [FDDeviceInfo collectDeviceAndAppInfo],
                                @"custom_data"  : [self getCustomData],
                                @"breadcrumbs"  : [self getBreadCrumbs],
                                @"debug_logs"   : [self getDebugLog]
                            };
        NSData *deviceAppData = [NSJSONSerialization dataWithJSONObject:deviceAppInfo options:kNilOptions error:nil];
        completion(deviceAppData);
    });
}

+(NSDictionary *)getCustomData{
    NSDictionary *customData = [[FDCustomData sharedInstance]getCustomData];
    return customData ? customData : @{};
}

+(NSArray *)getBreadCrumbs{
    NSArray *breadCrumbs = [[FDBreadCrumb sharedInstance]getCrumbs];
    return breadCrumbs ? breadCrumbs : @[];
}

+ (NSString *)getUUID{
    FDSecureStore *secureStore = [FDSecureStore sharedInstance];
    NSString *UUID = [secureStore objectForKey:MOBIHELP_DEFAULTS_DEVICE_UUID];
    if (!UUID) {
        UUID = [[NSUUID UUID]UUIDString];
        [secureStore setObject:UUID forKey:MOBIHELP_DEFAULTS_DEVICE_UUID];
    }
    return UUID;
}


#pragma mark - General Utitlites

/*  Expects value without any prefixes like - [0x or #]  */
+(UIColor *)colorWithHex:(NSString *)value{
    unsigned hexNum;
    NSScanner *scanner = [NSScanner scannerWithString:value];
    if (![scanner scanHexInt: &hexNum]) return nil;
    return [self colorWithRGBHex:hexNum];
}

+(UIColor *)colorWithRGBHex:(uint32_t)hex{
    int r = (hex >> 16) & 0xFF;
    int g = (hex >> 8) & 0xFF;
    int b = (hex) & 0xFF;
    return [UIColor colorWithRed:r / 255.0f
                           green:g / 255.0f
                            blue:b / 255.0f
                           alpha:1.0f];
}

+(NSString *)base64EncodedStringFromString:(NSString *)string{
    NSData *data = [NSData dataWithBytes:[string UTF8String] length:[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
    NSUInteger length = [data length];
    NSMutableData *mutableData = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t *input = (uint8_t *)[data bytes];
    uint8_t *output = (uint8_t *)[mutableData mutableBytes];
    for (NSUInteger i = 0; i < length; i += 3) {
        NSUInteger value = 0;
        for (NSUInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        static uint8_t const kAFBase64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        NSUInteger idx = (i / 3) * 4;
        output[idx + 0] = kAFBase64EncodingTable[(value >> 18) & 0x3F];
        output[idx + 1] = kAFBase64EncodingTable[(value >> 12) & 0x3F];
        output[idx + 2] = (i + 1) < length ? kAFBase64EncodingTable[(value >> 6)  & 0x3F] : '=';
        output[idx + 3] = (i + 2) < length ? kAFBase64EncodingTable[(value >> 0)  & 0x3F] : '=';
    }
    return [[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding];
}

+(NSBundle *)frameworkBundle {
    static NSBundle* frameworkBundle = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        NSString* mainBundlePath      = [[NSBundle mainBundle] resourcePath];
        NSString* frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:@"FreshdeskSDKResources.bundle"];
        frameworkBundle = [NSBundle bundleWithPath:frameworkBundlePath];
    });
    return frameworkBundle;
}

#pragma mark - App review request

+(BOOL)metReviewRequestCycle{
    NSInteger currentLaunchCount = [self appLaunchCount];
    NSInteger reviewRequestCount = [self appReviewLaunchCount];
    if (reviewRequestCount == 0) return NO;
    return (((currentLaunchCount % reviewRequestCount) == 0) && [self hasUserPreferredAppReview])? YES : NO;
}

+(NSInteger)appLaunchCount{
    FDSecureStore *secureStore = [FDSecureStore sharedInstance];
    BOOL isLaunchCountExist = [secureStore checkItemWithKey:MOBIHELP_DEFAULTS_APP_LAUNCH_COUNT];
    if (isLaunchCountExist) {
        return [secureStore intValueForKey:MOBIHELP_DEFAULTS_APP_LAUNCH_COUNT];
    }else{
        [self incrementLaunchCount];
        return 1;
    }
}

+(void)incrementLaunchCount{
    FDSecureStore *secureStore = [FDSecureStore sharedInstance];
    BOOL isLaunchCountExist = [secureStore checkItemWithKey:MOBIHELP_DEFAULTS_APP_LAUNCH_COUNT];
    if (isLaunchCountExist) {
        NSInteger launchCount = [secureStore intValueForKey:MOBIHELP_DEFAULTS_APP_LAUNCH_COUNT];
        [secureStore setIntValue:++launchCount forKey:MOBIHELP_DEFAULTS_APP_LAUNCH_COUNT];
    }else{
        [secureStore setIntValue:1 forKey:MOBIHELP_DEFAULTS_APP_LAUNCH_COUNT];
    }
}

+(NSInteger)appReviewLaunchCount{
    FDSecureStore *secureStore = [FDSecureStore sharedInstance];
    BOOL requestCount = [secureStore checkItemWithKey:MOBIHELP_DEFAULTS_APP_REVIEW_LAUNCH_COUNT];
    if (requestCount){
        return [secureStore intValueForKey:MOBIHELP_DEFAULTS_APP_REVIEW_LAUNCH_COUNT];
    }else{
        return 0;
    }
}

+(BOOL)hasUserPreferredAppReview{
    FDSecureStore *secureStore   = [FDSecureStore sharedInstance];
    NSString *rejectedAppVersion = [secureStore objectForKey:MOBIHELP_DEFAULTS_APP_REVIEW_REJECTED_VERSION];
    NSString *currentAppVersion  = [FDDeviceInfo appVersion];
    return(![rejectedAppVersion isEqualToString:currentAppVersion])? YES : NO;
}

+(void)stopFurtherReviewRequest{
    FDSecureStore *secureStore   = [FDSecureStore sharedInstance];
    [secureStore setObject:[FDDeviceInfo appVersion] forKey:MOBIHELP_DEFAULTS_APP_REVIEW_REJECTED_VERSION];
}

+(NSString *)sanitizeStringForNewLineCharacter:(NSString *)string{
    NSString *modifiedString = [FDUtilities replaceInString:string usingRegex:@"\\s+" replaceWith:@" "];
    modifiedString = [modifiedString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return modifiedString;
}

+(NSString *)sanitizeStringForUTF8:(NSString *)string {
    NSString *modifiedString = [FDUtilities replaceInString:string usingRegex:@"[\U00010000-\U0010ffff]" replaceWith:@" "];
    return modifiedString;
}

+(NSString *)replaceInString:(NSString *)string usingRegex:(NSString *)regexString replaceWith:(NSString *) replaceString{
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString
                                                                           options:NSRegularExpressionCaseInsensitive error:&error];
    if (error) {
        FDLog(@"Regex error : %@",error);
    }
    
    NSString *modifiedString = [regex stringByReplacingMatchesInString:string options:0
                                                                 range:NSMakeRange(0, [string length]) withTemplate:replaceString];
    return  modifiedString;
}

+(FEEDBACK_TYPE)getFeedBackType{
    NSInteger feedbackType = [[FDSecureStore sharedInstance] intValueForKey:MOBIHELP_DEFAULTS_APP_FEEDBACK_TYPE];
    if (!feedbackType) {
        feedbackType = FEEDBACK_TYPE_NAME_AND_EMAIL_REQUIRED;
    }
    return feedbackType;
}

+(void)assertMainThread{
    if (![NSThread isMainThread]) {
        NSString *exceptionName   = @"MOBIHELP_SDK_EXCEPTION_THREAD_BAD_ACCESS";
        NSString *exceptionReason = @"You are attempting to access main thread stuff from a background thread";
        [[[NSException alloc]initWithName:exceptionName reason:exceptionReason userInfo:nil]raise];
    }
}

+(NSString *)replaceSpecialCharacters:(NSString *)term with:(NSString *)replaceString{
    NSString *modifiedString;
    if(term){
        NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@"'#%^&{}[]>()/~|\\?:.<!$%&@,+*"];
        modifiedString = [[term componentsSeparatedByCharactersInSet:characterSet] componentsJoinedByString:replaceString];
        modifiedString = [modifiedString lowercaseString];
    }
    else{
        modifiedString = @"";
    }
    return modifiedString;
}

+(UIImage *)imageWithColor:(UIColor *)color{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end