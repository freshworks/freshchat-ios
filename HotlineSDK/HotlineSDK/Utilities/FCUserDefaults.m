//
//  HLUserDefaults.m
//  HotlineSDK
//
//  Created by Sanjith J K on 17/02/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCUserDefaults.h"
#import "FCMacros.h"

@implementation FCUserDefaults

+(void)setObject:(id)object forKey:(NSString *)key{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:object forKey:key];
    [defaults synchronize];
}

+ (void) setDictionary : (NSMutableDictionary *)dictionary forKey : (NSString *)key {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:dictionary] forKey:key];
    [defaults synchronize];
}

+ (NSDictionary *) getDictionary : (NSString *)key {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSData *dictData = [defaults objectForKey:key];
    NSDictionary *retrievedDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:dictData];
    return retrievedDictionary;
}

+ (void) setArray : (NSMutableArray *)array forKey : (NSString *)key{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:array forKey:key];
    [defaults synchronize];
}

+(id)getObjectForKey:(NSString *)key{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];    
    return [defaults objectForKey:key];
}


+(void)removeObjectForKey:(NSString *)key{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:key];
    [defaults synchronize];
}

+(void)setBool:(BOOL)value forKey:(NSString *)key{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:value forKey:key];
    [defaults synchronize];
}

+(BOOL)getBoolForKey:(NSString *)key{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:key];
}

+ (void) setFloat :(float)value forKey: (NSString *) key {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setFloat:value forKey:key];
    [defaults synchronize];
}

+ (float) getFloatForKey : (NSString *) key {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [defaults floatForKey:key];
}

+ (void) setLong : (long) value forKey : (NSString *) key{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(value) forKey:key];
    [defaults synchronize];
}

+ (long) getLongForKey : (NSString *) key{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [[defaults objectForKey:key] longValue];
}

+(void)setNumber:(NSNumber *)value forKey:(NSString *)key{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:key];
    [defaults synchronize];
}

+(NSNumber *)getNumberForKey:(NSString *)key{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:key];
}

+(void)setString:(NSString *)value forKey:(NSString *)key {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:value forKey:key];
    [defaults synchronize];
}

+(NSString*) getStringForKey:(NSString *)key {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [defaults stringForKey:key];
}

+ (void) setIntegerValue : (NSInteger)value forKey : (NSString *) key{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:value forKey:key];
    [defaults synchronize];
}

+ (NSInteger) getIntegerForKey : (NSString *) key{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [defaults integerForKey:key];
}

+(void)clearUserDefaults {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSArray * defaultsKey = @[FC_SOLUTIONS_LAST_RECEIVED_LOCALE, HOTLINE_DEFAULTS_CONTENT_LOCALE, FC_CHANNELS_LAST_RECEIVED_LOCALE, FRESHCHAT_DEFAULTS_SESSION_UPDATED_TIME,HOTLINE_DEFAULTS_IS_MESSAGE_SENT,FRESHCHAT_DEFAULTS_SESSION_UPDATED_TIME, CONFIG_RC_LAST_RESPONSE_TIME_EXPECTATION_FETCH_INTERVAL];
    for (NSString* key in defaultsKey) {
        [defaults removeObjectForKey:key];
    }
    [defaults synchronize];
}

+(void)log{
    FDLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
}

@end
