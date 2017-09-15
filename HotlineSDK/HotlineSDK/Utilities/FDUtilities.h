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

+(NSString *)currentUserAlias;
+(NSString *)getUserAliasWithCreate;

+(UIImage *)imageWithColor:(UIColor *)color;
+(NSString *) getKeyForObject:(NSObject *) object;
+(NSString *)getAdID;
+(NSString *)generateOfflineMessageAlias;
+(NSDictionary *)deviceInfoProperties;
+(void)setActivityIndicator:(BOOL)isVisible;
+(UIViewController*) topMostController;

+(void) AlertView:(NSString *)alertviewstring FromModule:(NSString *)pModule;
+(BOOL) isPoweredByHidden;
+(NSNumber *)getLastUpdatedTimeForKey:(NSString *)key;
+(NSString *)appName;
+(NSString*)deviceModelName;
+(NSString *) getTracker;
+(NSString *) returnLibraryPathForDir : (NSString *) directory;
+(NSDictionary*) filterValidUserPropEntries :(NSDictionary*) userDict;
+(NSArray *) convertTagsArrayToLowerCase : (NSArray *)tags;
+(BOOL)isiOS10;

+(void)initiatePendingTasks;
+(BOOL)hasInitConfig;
+(void)unreadCountInternalHandler:(void (^)(NSInteger count))completion;

+(BOOL) containsHTMLContent: (NSString *)content;
+(BOOL) containsString: (NSString *)original andTarget:(NSString *)target;
+ (BOOL) canMakeSessionCall;
+ (BOOL) canMakeDAUCall;
+(NSString *) typicalRepliesMsgForTime :(NSInteger)timeInSec;

+(NSString *) appendFirstName :(NSString *)firstName withLastName:(NSString *) lastName;

@end

#endif
