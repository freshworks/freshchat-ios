//
//  FDUtilities.m
//  FreshdeskSDK
//
//  Created by balaji on 15/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <asl.h>

#import "FDUtilities.h"
#import "FDSecureStore.h"
#import "HLMacros.h"
#import "HLLocalization.h"
#import <AdSupport/ASIdentifierManager.h>
#import <CommonCrypto/CommonDigest.h>

@implementation FDUtilities

#pragma mark - General Utitlites

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

+(BOOL)isUserRegistered{
    FDSecureStore *persistedStore = [FDSecureStore persistedStoreInstance];
    NSString *uuIdLookupKey = [FDUtilities getUUIDLookupKey];
    return [persistedStore checkItemWithKey:uuIdLookupKey];
}

+(NSString *) getUUIDLookupKey{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *uuIdLookupKey = [NSString stringWithFormat:@"%@-%@", appID ,HOTLINE_DEFAULTS_DEVICE_UUID ];
    return uuIdLookupKey;
}

+(NSString *)generateUUID{
    return [[NSUUID UUID]UUIDString];
}

//TODO: store existing konotor uuid to the store when absent during migration - Rex
+(NSString *)getUserAlias{
    FDSecureStore *persistedStore = [FDSecureStore persistedStoreInstance];
    return [persistedStore objectForKey:[FDUtilities getUUIDLookupKey]];
}

+(void)storeUserAlias:(NSString *)alias{
    FDSecureStore *persistedStore = [FDSecureStore persistedStoreInstance];
    [persistedStore setObject:alias forKey:[FDUtilities getUUIDLookupKey]];
}

+ (NSString*) stringRepresentationForDate:(NSDate*) date{
    NSString* timeString;
    
    NSArray* weekdays=[NSArray arrayWithObjects:
                       HLLocalizedString( LOC_DAY_SUNDAY ),
                       HLLocalizedString( LOC_DAY_MONDAY ),
                       HLLocalizedString( LOC_DAY_TUEDAY ),
                       HLLocalizedString( LOC_DAY_WEDNESDAY ),
                       HLLocalizedString( LOC_DAY_THURSDAY ),
                       HLLocalizedString( LOC_DAY_FRIDAY ),
                       HLLocalizedString( LOC_DAY_SATURDAY ),nil];
    
    NSDate* today=[[NSDate alloc] init];
    
#if (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0)
    NSCalendar* calendar=[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents* comp=[calendar components:(NSWeekdayCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:date];
    NSDateComponents* comp2=[calendar components:(NSWeekdayCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:today];
    
    NSDate* date2=[calendar dateFromComponents:comp];
    NSDate* today2=[calendar dateFromComponents:comp2];
    
    NSDateComponents* comp3=[calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:date2 toDate:today2 options:0];
    
#else
    NSCalendar* calendar=[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents* comp=[calendar components:(NSCalendarUnitWeekday|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:date];
    NSDateComponents* comp2=[calendar components:(NSCalendarUnitWeekday|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:today];
    
    NSDate* date2=[calendar dateFromComponents:comp];
    NSDate* today2=[calendar dateFromComponents:comp2];
    
    NSDateComponents* comp3=[calendar components:(NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:date2 toDate:today2 options:0];
    
#endif
    int days=(int)comp3.year*36+(int)comp3.month*30+(int)comp3.day;
    if([comp isEqual:comp2]){
        timeString=[NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
    }
    else{
        if((days>7)||(days<0)){
            timeString=[NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
        }
        else if(days==1)
            timeString=[NSString stringWithFormat:@"Yesterday %@",[NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle]];
        else if(days>1)
            timeString=[NSString stringWithFormat:@"%@ %@",[weekdays objectAtIndex:(comp.weekday-1)],[NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle]];
    }
    return timeString;
    
}

+(NSString *) getKeyForObject:(NSObject *) object {
    if(object){
        return [NSString stringWithFormat:@"%lu" , (unsigned long)[object hash]];
    }
    return @"nil";
}

+(NSString *)getAdID{
    FDSecureStore *secureStore = [FDSecureStore sharedInstance];
    NSString *adId = [secureStore objectForKey:HOTLINE_DEFAULTS_ADID];
    if (!adId) {
        adId = [self setAdId];
    }
    return adId;
}

+(NSString *)setAdId{
    FDSecureStore *secureStore = [FDSecureStore sharedInstance];
    NSString *adId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    [secureStore setObject:adId forKey:HOTLINE_DEFAULTS_ADID];
    return  adId;
}

+(NSString *)generateOfflineMessageAlias{
    NSString *randomString = [self generateUUID];
    return [NSString stringWithFormat:@"temp-%@", randomString];
}

+(BOOL)isValidEmail:(NSString *)email{
    NSString *emailPattern=@"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,15}";
    NSPredicate *emailPatternPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",emailPattern];
    return ([emailPatternPredicate evaluateWithObject:email]) ? YES : NO;
}

+(NSDictionary *)deviceInfoProperties{
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    
    UIDevice *device = [UIDevice currentDevice];
    
    [properties setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] forKey:@"app_version"];
    [properties setValue:@"Apple" forKey:@"brand"];
    
    [properties setValue:@"Apple" forKey:@"manufacturer"];
    [properties setValue:@"iPhone OS" forKey:@"os"];
    [properties setValue:[device systemVersion] forKey:@"os_version"];
    [properties setValue:[device model] forKey:@"model"];
    
    CGSize size = [UIScreen mainScreen].bounds.size;
    [properties setValue:[NSNumber numberWithInt:(int)size.height] forKey:@"screen_height"];
    [properties setValue:[NSNumber numberWithInt:(int)size.width] forKey:@"screen_width"];
    
    return [NSDictionary dictionaryWithDictionary:properties];
}

static NSInteger networkIndicator = 0;

+(void)setActivityIndicator:(BOOL)isVisible{
    if (isVisible){
        networkIndicator++;
    }
    else{
        if(networkIndicator > 0){
            networkIndicator--;
        }
        else{
            //NSLog(@"%@", @"Something wrong");
        }
    }
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(networkIndicator > 0)];
}

+(NSString *)getBaseURL{
    NSString *baseURL = [[FDSecureStore sharedInstance]objectForKey:HOTLINE_DEFAULTS_DOMAIN];
    return [NSString stringWithFormat:@"%@%@%@",@"https://",baseURL,@"/app/"];
}


+(void) AlertView:(NSString *)alertviewstring FromModule:(NSString *)pModule{
    NSString *pStr = [NSString stringWithFormat:@"%@:%@",pModule,alertviewstring ];
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle: pModule
                          message: pStr
                          delegate: nil
                          cancelButtonTitle:nil
                          otherButtonTitles:@"Ok",
                          nil];
    [alert show];
    return;
}

+(void) PostNotificationWithName :(NSString *) notName withObject: (id) object{
    NSNotification* not=[NSNotification notificationWithName:notName object:object];
    [[NSNotificationCenter defaultCenter] postNotification:not];
}

+ (NSString*)convertIntoMD5 :(NSString *) str
{
    // Create pointer to the string as UTF8
    const char *ptr = [str UTF8String];
    
    // Create byte array of unsigned chars
    unsigned char md5Buffer[16];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(ptr,(unsigned int) strlen(ptr), md5Buffer);
    
    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:16 * 2];
    for(int i = 0; i < 16; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}

+(BOOL)isPoweredByHidden{
    FDSecureStore *store = [FDSecureStore sharedInstance];

    NSString *secretKey = [store objectForKey:HOTLINE_DEFAULTS_SECRET_KEY];
    if (!secretKey) return NO;
    
    NSString* myString=[[store objectForKey:HOTLINE_DEFAULTS_APP_KEY] stringByAppendingString:[store objectForKey:HOTLINE_DEFAULTS_APP_ID]];
    
    NSMutableString *reversedString = [NSMutableString stringWithCapacity:[myString length]];
    
    [myString enumerateSubstringsInRange:NSMakeRange(0,[myString length])
                                 options:(NSStringEnumerationReverse | NSStringEnumerationByComposedCharacterSequences)
                              usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                  [reversedString appendString:substring];
                              }];
    
    return ([[self convertIntoMD5:reversedString] isEqualToString:secretKey]) ? YES : NO;
}

+(NSNumber *)getLastUpdatedTimeForKey:(NSString *)key{
    NSNumber *lastUpdateTime = [[FDSecureStore sharedInstance] objectForKey:key];
    if (lastUpdateTime == nil) lastUpdateTime = @0;
    return lastUpdateTime;
}

@end