//
//  FDUtilities.h
//  FreshdeskSDK
//
//  Created by balaji on 15/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#ifndef FreshdeskSDK_FDUtilities_h
#define FreshdeskSDK_FDUtilities_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FDStringUtil.h"

@interface FDUtilities : NSObject

+(NSString *)getUserAlias;

+(void)storeUserAlias:(NSString *)alias;
+(BOOL)isUserRegistered;

+(UIImage *)imageWithColor:(UIColor *)color;
+(NSString *) getKeyForObject:(NSObject *) object;
+(NSString *)getAdID;
+(NSString *)generateOfflineMessageAlias;
+(NSDictionary *)deviceInfoProperties;
+(void)setActivityIndicator:(BOOL)isVisible;

+(void) AlertView:(NSString *)alertviewstring FromModule:(NSString *)pModule;
+(BOOL) isPoweredByHidden;
+(NSNumber *)getLastUpdatedTimeForKey:(NSString *)key;
+(NSString *)appName;
+(NSString*)deviceModelName;
+(NSString *) getTracker;

@end

#endif