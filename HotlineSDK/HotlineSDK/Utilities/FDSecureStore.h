//
//  FDSecureStore.h
//  FreshdeskSDK
//
//  Created by Aravinth on 01/08/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#ifndef FreshdeskSDK_FDSecureStore_h
#define FreshdeskSDK_FDSecureStore_h

#import <Foundation/Foundation.h>

#define HOTLINE_DEFAULTS_USER_FIRST_NAME @"hotline_defaults_user_first_name"
#define HOTLINE_DEFAULTS_USER_LAST_NAME @"hotline_defaults_user_last_name"
#define HOTLINE_DEFAULTS_USER_EMAIL @"hotline_defaults_user_email"
#define HOTLINE_DEFAULTS_USER_PHONE_NUMBER @"hotline_defaults_user_phone_number"
#define HOTLINE_DEFAULTS_USER_PHONE_COUNTRY_CODE @"hotline_defaults_user_phone_country_code"
#define HOTLINE_DEFAULTS_USER_EXTERNAL_ID @"hotline_defaults_user_external_id"
#define HOTLINE_DEFAULTS_USER_RESTORE_ID @"hotline_defaults_user_restore_id"
#define HOTLINE_DEFAULTS_IS_DEVICE_TOKEN_REGISTERED @"hotline_defaults_is_device_token_registered"
#define HOTLINE_DEFAULTS_IS_USER_REGISTERED @"hotline_defaults_is_user_registered"
#define HOTLINE_DEFAULTS_APP_VERSION @"hotline_defaults_app_version"
#define HOTLINE_DEFAULTS_SDK_BUILD_NUMBER @"hotline_defaults_sdk_build_number"
#define HOTLINE_DEFAULTS_APP_ID @"hotline_defaults_app_id"
#define HOTLINE_DEFAULTS_DOMAIN @"hotline_defaults_domain"
#define HOTLINE_DEFAULTS_THEME_NAME @"hotline_defaults_theme_name"
#define HOTLINE_DEFAULTS_APP_KEY @"hotline_defaults_app_key"
#define HOTLINE_DEFAULTS_VOICE_MESSAGE_ENABLED @"hotline_defaults_voice_message_enabled"
#define HOTLINE_DEFAULTS_GALLERY_SELECTION_ENABLED @"hotline_defaults_gallery_selection_enabled"
#define HOTLINE_DEFAULTS_NOTIFICATION_SOUND_ENABLED @"hotline_defaults_notification_sound_enabled"
#define HOTLINE_DEFAULTS_AGENT_AVATAR_ENABLED @"hotline_defaults_agent_avatar_enabled"
#define HOTLINE_DEFAULTS_SHOW_NOTIFICATION_BANNER @"hotline_defaults_show_notification_banner"
#define HOTLINE_DEFAULTS_CAMERA_CAPTURE_ENABLED @"hotline_defaults_camera_capture_enabled"
#define HOTLINE_DEFAULTS_SHOW_CHANNEL_THUMBNAIL @"hotline_defaults_show_channel_thumbnail"
#define HOTLINE_DEFAULTS_CONVERSATION_BANNER_MESSAGE @"hotline_conversation_banner_message"
#define HOTLINE_DEFAULTS_ADID @"hotline_defaults_adid"
#define HOTLINE_DEFAULTS_OLD_USER_INFO @"hotline_defaults_old_user_info"

#define FRESHCHAT_CONFIG_RC_FAQ_ENABLED @"freshchat_config_rc_faq_enabled"
#define FRESHCHAT_CONFIG_RC_INBOX_ENABLED @"freshchat_config_rc_inbox_enabled"
#define FRESHCHAT_CONFIG_RC_AUTO_CAMPAIGNS_ENABLED @"freshchat_config_rc_auto_campaigns_enabled"
#define FRESHCHAT_CONFIG_RC_MANUAL_CAMPAIGNS_ENABLED @"freshchat_config_rc_manual_campaigns_enabled"
#define FRESHCHAT_CONFIG_RC_USER_EVENTS_ENABLED @"freshchat_config_rc_user_events_enabled"
#define FRESHCHAT_CONFIG_RC_AOT_USER_CREATE_ENABLED @"freshchat_config_rc_aot_user_create_enabled"
#define FRESHCHAT_CONFIG_RC_CUSTOM_BRAND_BANNER_ENABLED @"freshchat_config_rc_custom_brand_banner_enabled"
#define FRESHCHAT_CONFIG_RC_SHOW_AGENT_AVATAR @"freshchat_config_rc_show_agent_avatar"
#define FRESHCHAT_CONFIG_RC_SHOW_REAL_AGENT_AVATAR @"freshchat_config_rc_show_real_agent_avatar"
#define FRESHCHAT_CONFIG_RC_LAUNCH_DEEPLINK_NOTIFICATION @"freshchat_config_rc_launch_deeplink_notification"

#define HOTLINE_DEFAULTS_SOLUTIONS_LAST_UPDATED_SERVER_TIME @"hotline_defaults_solutions_last_updated_svr_time_v3"
//v2 - Version for Force reload of data from server for Tag Data
#define FC_SOLUTIONS_LAST_REQUESTED_TIME @"hotline_defaults_solutions_last_updated_itv_time_v3"

#define FC_CHANNELS_LAST_MODIFIED_AT @"hotline_defaults_channels_last_updated_svr_time_v2"
#define FC_CHANNELS_LAST_REQUESTED_TIME @"hotline_defaults_channels_last_updated_itv_time_v2"

#define FC_CONVERSATIONS_LAST_MODIFIED_AT @"hotline_defaults_conversations_last_updated_svr_time"
#define FC_CONVERSATIONS_LAST_REQUESTED_TIME @"hotline_defaults_conversations_last_updated_itv_time"

#define HOTLINE_DEFAULTS_DAU_LAST_UPDATED_TIME @"hotline_defaults_dau_last_updated_time"

#define HOTLINE_DEFAULTS_PUSH_TOKEN @"hotline_defaults_push_token"
//#define HOTLINE_DEFAULTS_NOTIFICATION_DISABLED_ALERT_SHOWN @"hotline_defaults_notification_disabled_alert_shown"
//Removed as it is not more required, was available as part of push prompt check

#define HOTLINE_DEFAULTS_VOTED_ARTICLES @"hotline_defaults_voted_articles"
#define HOTLINE_DEFAULTS_STRINGS_BUNDLE @"hotline_defaults_strings_bundle"

#define FRESHCHAT_DEFAULTS_IS_ACCOUNT_DELETED @"freshchat_defaults_is_account_deleted"

//Keys used in persisted store
#define HOTLINE_DEFAULTS_DEVICE_UUID @"hotline_defaults_device_uuid"

@interface FDSecureStore : NSObject

+(instancetype)sharedInstance;
+(instancetype)persistedStoreInstance;

-(void)setIntValue:(NSInteger)value forKey:(NSString *)key;
-(NSInteger)intValueForKey:(NSString *)key;

-(void)setBoolValue:(BOOL)value forKey:(NSString *)key;
-(BOOL)boolValueForKey:(NSString *)key;

-(void)setObject:(id)object forKey:(NSString *)key;
-(id)objectForKey:(NSString *)key;

//Check if an item exists
-(BOOL)checkItemWithKey:(NSString *)key;

-(void)removeObjectWithKey:(NSString *)key;
-(void)clearStoreData;

@end

#endif
