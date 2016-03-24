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

#define HOTLINE_DEFAULTS_USER_NAME @"hotline_defaults_user_name"
#define HOTLINE_DEFAULTS_USER_EMAIL @"hotline_defaults_user_email"
#define HOTLINE_DEFAULTS_USER_PHONE_NUMBER @"hotline_defaults_user_phone_number"
#define HOTLINE_DEFAULTS_USER_PHONE_COUNTRY_CODE @"hotline_defaults_user_phone_country_code"
#define HOTLINE_DEFAULTS_USER_EXTERNAL_ID @"hotline_defaults_user_external_id"
#define HOTLINE_DEFAULTS_IS_DEVICE_TOKEN_REGISTERED @"hotline_defaults_is_device_token_registered"
#define HOTLINE_DEFAULTS_IS_USER_REGISTERED @"hotline_defaults_is_user_registered"
#define HOTLINE_DEFAULTS_APP_VERSION @"hotline_defaults_app_version"
#define HOTLINE_DEFAULTS_SDK_BUILD_NUMBER @"hotline_defaults_sdk_build_number"
#define HOTLINE_DEFAULTS_APP_ID @"hotline_defaults_app_id"
#define HOTLINE_DEFAULTS_DOMAIN @"hotline_defaults_domain"
#define HOTLINE_DEFAULTS_APP_KEY @"hotline_defaults_app_key"
#define HOTLINE_DEFAULTS_VOICE_MESSAGE_ENABLED @"hotline_defaults_voice_message_enabled"
#define HOTLINE_DEFAULTS_PICTURE_MESSAGE_ENABLED @"hotline_defaults_picture_message_enabled"
#define HOTLINE_DEFAULTS_NOTIFICATION_SOUND_ENABLED @"hotline_defaults_notification_sound_enabled"
#define HOTLINE_DEFAULTS_AGENT_AVATAR_ENABLED @"hotline_defaults_agent_avatar_enabled"
#define HOTLINE_DEFAULTS_SHOW_NOTIFICATION_BANNER @"hotline_defaults_show_notification_banner"
#define HOTLINE_DEFAULTS_DISPLAY_SOLUTION_AS_GRID @"hotline_defaults_display_solutions_as_grid"
#define HOTLINE_DEFAULTS_CAMERA_CAPTURE_ENABLED @"hotline_defaults_camera_capture_enabled"
#define HOTLINE_DEFAULTS_SHOW_CHANNEL_THUMBNAIL @"hotline_defaults_show_channel_thumbnail"
#define HOTLINE_DEFAULTS_CONVERSATION_BANNER_MESSAGE @"hotline_conversation_banner_message"
#define HOTLINE_DEFAULTS_ADID @"hotline_defaults_adid"
#define HOTLINE_DEFAULTS_SOLUTIONS_LAST_UPDATED_TIME @"hotline_defaults_solutions_last_updated_time"
#define HOTLINE_DEFAULTS_CHANNELS_LAST_UPDATED_TIME @"hotline_defaults_channels_last_updated_time"
#define HOTLINE_DEFAULTS_CONVERSATIONS_LAST_UPDATED_TIME @"hotline_defaults_conversations_last_updated_time"
#define HOTLINE_DEFAULTS_PUSH_TOKEN @"hotline_defaults_push_token"
#define HOTLINE_DEFAULTS_NOTIFICATION_DISABLED_ALERT_SHOWN @"hotline_defaults_notification_disabled_alert_shown"

#define HOTLINE_DEFAULTS_VOTED_ARTICLES @"hotline_defaults_voted_articles"

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
