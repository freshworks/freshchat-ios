//
//  FDStringUtil.h
//  HotlineSDK
//
//  Created by Hrishikesh on 29/02/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#ifndef FDStringUtil_h
#define FDStringUtil_h

@interface FDStringUtil : NSObject

+(BOOL)isValidEmail:(NSString *)email;
+(NSString *)generateUUID;
+(NSString *)base64EncodedStringFromString:(NSString *)string;
+(NSString *)sanitizeStringForUTF8:(NSString *)string;
+(NSString *)sanitizeStringForNewLineCharacter:(NSString *)string;
+(NSString *)replaceSpecialCharacters:(NSString *)term with:(NSString *)replaceString;
+(NSString*)stringRepresentationForDate:(NSDate*) date;

@end


#endif /* FDStringUtil_h */
