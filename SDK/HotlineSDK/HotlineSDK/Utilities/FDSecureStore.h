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

#define HOTLINE_DEFAULTS_SOLUTIONS_LAST_UPDATED_TIME @"hotline_defaults_solutions_last_updated_time"
#define HOTLINE_DEFAULTS_CHANNELS_LAST_UPDATED_TIME @"hotline_defaults_channels_last_updated_time"
#define HOTLINE_DEFAULTS_DEVICE_UUID @"hotline_defaults_device_uuid"
#define HOTLINE_DEFAULTS_APP_ID @"hotline_defaults_app_id"
#define HOTLINE_DEFAULTS_APP_KEY @"hotline_defaults_app_key"

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