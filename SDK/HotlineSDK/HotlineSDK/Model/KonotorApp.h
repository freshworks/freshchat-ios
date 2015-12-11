//
//  KonotorApp.h
//  Konotor
//
//  Created by Vignesh G on 19/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface KonotorApp : NSManagedObject

@property (nonatomic, retain) NSString * appID;
@property (nonatomic, retain) NSString * appKey;
@property (nonatomic, retain) NSString * appVersion;
@property (nonatomic, retain) NSString * sdkVersion;

@property (nonatomic, retain) NSString * deviceToken;
@property (nonatomic) BOOL deviceTokenUpdatedOnServer;
@property (nonatomic,retain) NSNumber* audioPermissionGiven;
@property (nonatomic, retain) NSNumber * lastUpdatedConversation;

+(BOOL)initWithAppID: (NSString *)AppID WithAppKey: (NSString *) AppKey;
+(NSString *) GetAppID;
+(NSString *) GetAppKey;
+(void) addDeviceToken:(NSString *)deviceToken;
+(void) successfullyUpdatedDeviceTokenOnServer;
+(NSNumber*) getLastUpdatedConversationsTimeStamp;
+(void) updateLastUpdatedConversations:(NSNumber *) lastUpdated;
+(void) updateUserBeingCreated:(BOOL) status;
+(NSString *) getAppVersion;
+(NSString *) getSDKVersion;
+(void) SendCachedTokenIfNotUpdated;
+(NSString *) GetCachedDeviceToken;

+(BOOL) isUserBeingCreated;
+(BOOL) getAppInitStatus;
+(void) UpdateAppAndSDKVersions;
+(void) UpdateAppVersion: (NSString *) appVersion;
+(void) UpdateSDKVersion: (NSString *) sdkVersion;

@end