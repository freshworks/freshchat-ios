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

@end