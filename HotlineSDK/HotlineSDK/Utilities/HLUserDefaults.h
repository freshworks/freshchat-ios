//
//  HLUserDefaults.h
//  HotlineSDK
//
//  Created by Sanjith J K on 17/02/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

#define HOTLINE_DEFAULTS_FAQ_LOCALEID @"hotline_defaults_faq_localeid"
#define HOTLINE_DEFAULTS_CONV_LOCALEID @"hotline_defaults_conv_localeid"
#define HOTLINE_DEFAULTS_CONTENT_LOCALE @"hotline_defaults_content_locale"
#define HOTLINE_DEFAULTS_IS_USER_DEFERED @"hotline_defaults_is_user_defered"
#define HOTLINE_DEFAULTS_IS_MESSAGE_SENT @"hotline_defaults_is_message_sent"

@interface HLUserDefaults : NSObject

+(void)setObject:(id)object forKey:(NSString *)key;
+(id) getObjectForKey:(NSString *)key;

+(BOOL)getBoolForKey:(NSString *)key;
+(void)setBool:(BOOL)value forKey:(NSString *)key;

+(void)setNumber:(NSNumber *)value forKey:(NSString *)key;
+(NSNumber *)getNumberForKey:(NSString *)key;

+(void)setString:(NSString *)value forKey:(NSString *)key;
+(NSString *) getStringForKey:(NSString *)key;

+(void)removeObjectForKey:(NSString *)key;

+(void)clearUserDefaults;

+(void)log;

@end
