//
//  HLUserDefaults.h
//  HotlineSDK
//
//  Created by Sanjith J K on 17/02/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

#define HOTLINE_DEFAULTS_CONTENT_LOCALEID @"hotline_defaults_content_localeid"
#define HOTLINE_DEFAULTS_CONTENT_LOCALE @"hotline_defaults_content_locale"

#define CONFIG_RC_ACTIVE_CONV_WINDOW @"config_rc_active_conv_window"
#define CONFIG_RC_SESSION_DURATION_SECS @"config_rc_session_duration_secs"
#define CONFIG_RC_ACTIVE_CONV_FETCH_BACKOFF_RATIO @"config_rc_active_conv_fetch_backoff_ratio"
#define CONFIG_RC_ACTIVE_CONV_MAX_FETCH_INTERVAL @"config_rc_active_conv_max_fetch_interval"
#define CONFIG_RC_ACTIVE_CONV_MIN_FETCH_INTERVAL @"config_rc_active_conv_min_fetch_interval"
#define CONFIG_RC_ACTIVE_CONV_WINDOW @"config_rc_active_conv_window"
#define CONFIG_RC_CHANNELS_FETCH_INTERVAL_LAIDBACK @"config_rc_channels_fetch_interval_laidback"
#define CONFIG_RC_CHANNELS_FETCH_INTERVAL_NORMAL @"config_rc_channels_fetch_interval_normal"
#define CONFIG_RC_FAQ_FETCH_INTERVAL_LAIDBACK @"config_rc_faq_fetch_interval_laidback"
#define CONFIG_RC_FAQ_FETCH_INTERVAL_NORMAL @"config_rc_faq_fetch_interval_normal"
#define CONFIG_RC_IS_ACCOUNT_ACTIVE @"config_rc_is_account_active"
#define CONFIG_RC_MSG_FETCH_INTERVAL_LAIDBACK @"config_rc_msg_fetch_interval_laidback"
#define CONFIG_RC_MSG_FETCH_INTERVAL_NORMAL @"config_rc_msg_fetch_interval_normal"
#define CONFIG_RC_ENABLE_FEATURES @"config_rc_enable_features"
#define CONFIG_RC_API_FETCH_INTERVAL @"config_rc_api_fetch_interval"

@interface HLUserDefaults : NSObject

+(void)setObject:(id)object forKey:(NSString *)key;
+(id) getObjectForKey:(NSString *)key;

+(BOOL)getBoolForKey:(NSString *)key;
+(void)setBool:(BOOL)value forKey:(NSString *)key;

+(void)setNumber:(NSNumber *)value forKey:(NSString *)key;
+(NSNumber *)getNumberForKey:(NSString *)key;

+(void)setString:(NSString *)value forKey:(NSString *)key;
+(NSString *) getStringForKey:(NSString *)key;

+ (void) setArray : (NSMutableArray *)array forKey : (NSString *)key;

+(void)removeObjectForKey:(NSString *)key;

+(void)clearUserDefaults;

+(void)log;

@end
