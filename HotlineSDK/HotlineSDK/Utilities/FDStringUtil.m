//
//  FDStringUtil.h
//  HotlineSDK
//
//  Created by Hrishikesh on 29/02/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FDStringUtil.h"
#import "HLLocalization.h"
#import "HLMacros.h"


@implementation FDStringUtil

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


+(NSString *)sanitizeStringForNewLineCharacter:(NSString *)string{
    NSString *modifiedString = [FDStringUtil replaceInString:string usingRegex:REGEX_WHITESPACE replaceWith:@" "];
    modifiedString = [modifiedString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return modifiedString;
}

+(NSString *)sanitizeStringForUTF8:(NSString *)string {
    NSString *modifiedString = [FDStringUtil replaceInString:string usingRegex:REGEX_NON_UTF8 replaceWith:@" "];
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

+(NSString *)generateUUID{
    NSString *UUID = [[NSUUID UUID]UUIDString];
    if (UUID == nil) {
        CFUUIDRef uuidRef = CFUUIDCreate(NULL);
        CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
        CFRelease(uuidRef);
        UUID = (__bridge_transfer NSString *)uuidStringRef;
        FDLog(@"Note! NSUUID is nil, using CFUUID instead");
    }
    return UUID;
}

+(BOOL)isValidEmail:(NSString *)email{
    NSString *emailPattern=@"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,15}";
    NSPredicate *emailPatternPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",emailPattern];
    return ([emailPatternPredicate evaluateWithObject:email]) ? YES : NO;
}

+(BOOL) isValidUserPropName : (NSString *)name{
    NSString *propertyPattern = @"[A-Z0-9a-z _-]+";
    NSPredicate *propertyPatternPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",propertyPattern];
    return ([propertyPatternPredicate evaluateWithObject:name]) ? YES : NO;
}

+(NSString*) stringRepresentationForDate:(NSDate*) date{
    NSString* timeString;
    
    NSArray* weekdays=[NSArray arrayWithObjects:
                       HLLocalizedString( LOC_DAY_SUNDAY ),
                       HLLocalizedString( LOC_DAY_MONDAY ),
                       HLLocalizedString( LOC_DAY_TUESDAY ),
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


+(BOOL) checkRegexPattern:(NSString *)regexStr inString:(NSString *)string{
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexStr
                                                                           options:NSRegularExpressionCaseInsensitive error:&error];
    if (error) {
        FDLog(@"Regex error : %@",error);
    }
    NSArray<NSTextCheckingResult *> *matches =  [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];
    return [matches count] > 0;
}

+(BOOL)isNotEmptyString:(NSString *)str{
    return str && ([trimString(str) length] > 0);
}

+(BOOL)isEmptyString:(NSString *)str{
    return ![FDStringUtil isNotEmptyString:trimString(str)];
}
@end
