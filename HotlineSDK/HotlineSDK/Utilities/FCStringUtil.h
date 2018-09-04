//
//  FDStringUtil.h
//  HotlineSDK
//
//  Created by Hrishikesh on 29/02/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#ifndef FDStringUtil_h
#define FDStringUtil_h

#define REGEX_MEDIA_CONTENT @"<\\s+(img|iframe).*?src\\s+=[ '\"]+http[s]?:\\/\\/.*?>";
#define REGEX_NON_UTF8 @"[\U00010000-\U0010ffff]"
#define REGEX_WHITESPACE @"\\s+"

@interface FCStringUtil : NSObject

+(BOOL)isValidEmail:(NSString *)email;
+(BOOL) isValidUserPropName : (NSString *)name;
+(NSString *)generateUUID;
+(NSString *)base64EncodedStringFromString:(NSString *)string;
+(NSString *)sanitizeStringForUTF8:(NSString *)string;
+(NSString *)sanitizeStringForNewLineCharacter:(NSString *)string;
+(NSString *)replaceSpecialCharacters:(NSString *)term with:(NSString *)replaceString;
+(BOOL) checkRegexPattern:(NSString *)regex inString:(NSString *)string;
+(NSString *)replaceInString:(NSString *)string usingRegex:(NSString *)regexString replaceWith:(NSString *) replaceString;
+(BOOL)isNotEmptyString:(NSString *)str;
+(BOOL)isEmptyString:(NSString *)str;

@end

#endif /* FDStringUtil_h */