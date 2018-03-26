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
#define FRESHCHAT_DEFAULTS_SESSION_UPDATED_TIME @"freshchat_defaults_session_updated_time"

#define FRESHCHAT_DEFAULTS_ISUSER_RESTORE_CALLED @"freshchat_defaults_isuser_restore_called"

#define CONFIG_RC_AGENT_AVATAR_TYPE @"config_rc_agent_avatar_type"
#define CONFIG_RC_NOTIFICATION_DEEPLINK_ENABLED @"config_rc_notification_deeplink_enabled"

#define CONFIG_RC_ACTIVE_CONV_WINDOW @"config_rc_active_conv_window"
#define CONFIG_RC_SESSION_TIMEOUT_INTERVAL @"config_rc_session_timeout_interval"
#define CONFIG_RC_ACTIVE_CONV_FETCH_BACKOFF_RATIO @"config_rc_active_conv_fetch_backoff_ratio"

#define CONFIG_RC_ACTIVE_CONV_MAX_FETCH_INTERVAL @"config_rc_active_conv_max_fetch_interval"
#define CONFIG_RC_ACTIVE_CONV_MIN_FETCH_INTERVAL @"config_rc_active_conv_min_fetch_interval"

#define CONFIG_RC_CHANNELS_FETCH_INTERVAL_LAIDBACK @"config_rc_channels_fetch_interval_laidback"
#define CONFIG_RC_CHANNELS_FETCH_INTERVAL_NORMAL @"config_rc_channels_fetch_interval_normal"

#define CONFIG_RC_FAQ_FETCH_INTERVAL_LAIDBACK @"config_rc_faq_fetch_interval_laidback"
#define CONFIG_RC_FAQ_FETCH_INTERVAL_NORMAL @"config_rc_faq_fetch_interval_normal"

#define CONFIG_RC_IS_ACCOUNT_ACTIVE @"config_rc_is_account_active"

#define CONFIG_RC_MSG_FETCH_INTERVAL_LAIDBACK @"config_rc_msg_fetch_interval_laidback"
#define CONFIG_RC_MSG_FETCH_INTERVAL_NORMAL @"config_rc_msg_fetch_interval_normal"

#define CONFIG_RC_ENABLE_FEATURES @"config_rc_enable_features"

#define CONFIG_RC_API_FETCH_INTERVAL @"config_rc_api_fetch_interval"
#define CONFIG_RC_LAST_API_FETCH_INTERVAL_TIME @"config_rc_last_api_fetch_interval_time"

#define CONFIG_RC_RESPONSE_TIME_EXPECTATION_FETCH_INTERVAL @"config_rc_response_time_expectations_fetch_interval"
#define CONFIG_RC_LAST_RESPONSE_TIME_EXPECTATION_FETCH_INTERVAL @"config_rc_last_response_time_expectation_fetch_interval"
#define FRESHCHAT_RESPONSE_TIME_EXPECTATION_VALUE @"freshchat_response_time_expectation_value"
#define FRESHCHAT_RESPONSE_TIME_7_DAYS_VALUE @"freshchat_response_time_7_days_value"

#define FRESHCHAT_DEFAULTS_USER_IOS_VERSION @"freshchat_defaults_user_ios_version"

@interface HLUserDefaults : NSObject

+(void)setObject:(id)object forKey:(NSString *)key;
+(id) getObjectForKey:(NSString *)key;

+(BOOL)getBoolForKey:(NSString *)key;
+(void)setBool:(BOOL)value forKey:(NSString *)key;

+(void)setNumber:(NSNumber *)value forKey:(NSString *)key;
+(NSNumber *)getNumberForKey:(NSString *)key;

+(void)setString:(NSString *)value forKey:(NSString *)key;
+(NSString *) getStringForKey:(NSString *)key;

+ (void) setFloat :(float)value forKey: (NSString *) key;
+ (float) getFloatForKey : (NSString *) key;

+ (void) setLong : (long) value forKey : (NSString *) key;
+ (long) getLongForKey : (NSString *) key;

+ (void) setIntegerValue : (NSInteger)value forKey : (NSString *) key;
+ (NSInteger) getIntegerForKey : (NSString *) key;

+ (void) setArray : (NSMutableArray *)array forKey : (NSString *)key;

+ (void) setDictionary : (NSMutableDictionary *)dictionary forKey : (NSString *)key;
+ (NSDictionary *) getDictionary:(NSString *)key;

+(void)removeObjectForKey:(NSString *)key;

+(void)clearUserDefaults;

+(void)log;

@end
