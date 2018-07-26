//
//  FDStringUtil.h
//  HotlineSDK
//
//  Created by Hrishikesh on 29/02/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FCStringUtil.h"
#import "FCLocalization.h"
#import "FCMacros.h"

@implementation FCStringUtil

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
    NSString *modifiedString = [FCStringUtil replaceInString:string usingRegex:REGEX_WHITESPACE replaceWith:@" "];
    modifiedString = [modifiedString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return modifiedString;
}

+(NSString *)sanitizeStringForUTF8:(NSString *)string {
    NSString *modifiedString = [FCStringUtil replaceInString:string usingRegex:REGEX_NON_UTF8 replaceWith:@" "];
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
    return ![FCStringUtil isNotEmptyString:trimString(str)];
}
@end
