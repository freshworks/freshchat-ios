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

//MOBIHELP_DEFAULTS_CREDENTIALS
#define MOBIHELP_DEFAULTS_API_KEY                        @"mobihelp_defaults_api_key"
#define MOBIHELP_DEFAULTS_SUPPORT_SITE                   @"mobihelp_defaults_support_site"
#define MOBIHELP_DEFAULTS_APP_KEY                        @"mobihelp_defaults_app_key"
#define MOBIHELP_DEFAULTS_APP_SECRET                     @"mobihelp_defaults_app_secret"
#define MOBIHELP_DEFAULTS_DEVICE_UUID                    @"mobihelp_defaults_device_uuid"
#define MOBIHELP_DEFAULTS_DEVICE_REGISTRATION_STATUS     @"mobihelp_defaults_device_registration_status"
#define MOBIHELP_DEFAULTS_APP_BUNDLE_IDENTIFIER          @"mobihelp_defaults_app_bundle_identifier"
#define MOBIHELP_DEFAULTS_IS_PAID_USER                   @"mobihelp_defaults_is_paid_user"

//MOBIHELP_DEFAULTS_APP_INFO
#define MOBIHELP_DEFAULTS_APP_CONFIG_LAST_UPDATED_TIME   @"mobihelp_defaults_app_config_last_updated_time"
#define MOBIHELP_DEFAULTS_SOLUTIONS_LAST_UPDATED_TIME_V2 @"mobihelp_defaults_solutions_last_updated_time_v2"
#define MOBIHELP_DEFAULTS_TICKETS_LAST_UPDATED_TIME      @"mobihelp_defaults_tickets_last_updated_time"
#define MOBIHELP_DEFAULTS_CUSTOM_DATA                    @"mobihelp_defaults_custom_data"
#define MOBIHELP_DEFAULTS_BREAD_CRUMBS                   @"mobihelp_defaults_bread_crumbs"
#define MOBIHELP_DEFAULTS_APP_FEEDBACK_TYPE              @"mobihelp_defaults_app_feedback_type"
#define MOBIHELP_DEFAULTS_IS_SSL_ENABLED                 @"mobihelp_defaults_is_ssl_enabled"
#define MOBIHELP_DEFAULTS_IS_AUTO_REPLY_ENABLED          @"mobihelp_defaults_is_auto_reply_enabled"
#define MOBIHELP_DEFAULTS_IS_ENHANCED_PRIVACY_ENABLED    @"mobihelp_defaults_is_enhanced_privacy_enabled"
#define MOBIHELP_DEFAULTS_IS_CONVERSATIONS_DISABLED      @"mobihelp_defaults_is_conversations_disabled"
#define MOBIHELP_DEFAULTS_SOLUTION_PREFETCH_PREFERENCE   @"mobihelp_defaults_solution_prefetch_preference"

//MOBIHELP_DEFAULTS_APP_STATE
#define MOBIHELP_DEFAULTS_IS_APP_DELETED                 @"mobihelp_defaults_is_app_deleted"
#define MOBIHELP_DEFAULTS_IS_ACCOUNT_SUSPENDED           @"mobihelp_defaults_is_account_suspended"
#define MOBIHELP_DEFAULTS_IS_INVALID_APP                 @"mobihelp_default_is_invalid_app"

//MOBIHELP_DEFAULTS_USER_INFO
#define MOBIHELP_DEFAULTS_USER_NAME                      @"mobihelp_defaults_user_name"
#define MOBIHELP_DEFAULTS_USER_EMAIL_ADDRESS             @"mobihelp_defaults_user_email_address"
#define MOBIHELP_DEFAULTS_USER_REGISTRATION_STATUS       @"mobihelp_defaults_user_registration_status"

//MOBIHELP_DEFAULTS_APP_REVIEW
#define MOBIHELP_DEFAULTS_APP_STORE_ID                   @"mobihelp_defaults_app_store_id"
#define MOBIHELP_DEFAULTS_APP_REVIEW_REJECTED_VERSION    @"mobihelp_defaults_app_review_rejected_version"
#define MOBIHELP_DEFAULTS_APP_LAUNCH_COUNT               @"mobihelp_defaults_app_launch_count"
#define MOBIHELP_DEFAULTS_APP_REVIEW_LAUNCH_COUNT        @"mobihelp_defaults_app_review_launch_count"

//MOBIHELP CREATE INDEX COMPLETION
#define MOBIHELP_DEFAULTS_IS_INDEX_CREATED @"mobihelp_defaults_is_index_created"

@interface FDSecureStore : NSObject

+(instancetype)sharedInstance;

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

//Test
-(void)logStoreData;

@end

#endif