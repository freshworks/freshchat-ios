//
//  FDLocaleUtil.m
//  HotlineSDK
//
//  Created by Sanjith J K on 17/02/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCLocaleUtil.h"
#import "FCUserDefaults.h"
#import "FCUtilities.h"
#import "FCSecureStore.h"
#import "FCLocaleConstants.h"
#import "FCMacros.h"

@implementation FCLocaleUtil


+(NSNumber *)getContentLocaleId{
    return [FCUserDefaults getNumberForKey:FC_SOLUTIONS_LAST_RECEIVED_LOCALE];
}

+(NSNumber *) getConvLocaleId{
    return [FCUserDefaults getNumberForKey:FC_CHANNELS_LAST_RECEIVED_LOCALE];
}

+(NSString *)getUserLocale{
    NSString *userLocale = [FCUserDefaults getStringForKey:HOTLINE_DEFAULTS_CONTENT_LOCALE];
    return ( userLocale != nil ) ? userLocale : @"";
}

+(NSArray *)userLocaleParams:(BOOL)voteReq {
    NSString *localLocale = [self getLocalLocale];
    NSMutableArray *params = [[NSMutableArray alloc]init];
    [params addObject:[NSString stringWithFormat:PARAM_LOCALE,localLocale]];
    NSNumber *defaultLocaleId   = [FCLocaleUtil getContentLocaleId];
    if([defaultLocaleId compare:@0] == NSOrderedDescending) {
        if(voteReq) {
            [params addObject:[NSString stringWithFormat:PARAM_LOCALEID,defaultLocaleId]];
        } else {
            [params addObject:[NSString stringWithFormat:PARAM_LAST_LOCALEID,defaultLocaleId]];
        }
    }
    return params;
}

+ (NSArray *) channelLocaleParams{
    NSString *localLocale = [self getLocalLocale];
    NSMutableArray *params = [[NSMutableArray alloc]init];
    [params addObject:[NSString stringWithFormat:PARAM_LOCALE,localLocale]];
    NSNumber *defaultLocaleId = [FCLocaleUtil getConvLocaleId];
    if(!defaultLocaleId){
        defaultLocaleId = [NSNumber numberWithInt:0];
    }
    [params addObject:[NSString stringWithFormat:PARAM_LAST_LOCALEID,defaultLocaleId]];
    return params;
}

+(NSString *)getLocalLocale{
    NSString *locale = [[NSLocale preferredLanguages] objectAtIndex:0]; //Current configured Locale
    return locale;
}

+(void)updateLocaleWith:(NSString *)locale {
    [FCUserDefaults setObject:locale forKey:HOTLINE_DEFAULTS_CONTENT_LOCALE];
}

+ (void)updateLocale{
    if([self hadLocaleChange]) {
        NSString *localLocale = [FCLocaleUtil getLocalLocale];
        [FCLocaleUtil updateLocaleWith:localLocale];
    }
}

+(BOOL)hadLocaleChange {
    NSString *localLocale = [self getLocalLocale];
    NSString *userLocale = [self getUserLocale];
    BOOL hasChanged = !([localLocale isEqualToString:userLocale]);
    if (hasChanged) {
        FDLog(@"Locale change from %@ -> %@",userLocale,localLocale);
    }
    return hasChanged;
}

@end
