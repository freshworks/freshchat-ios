//
//  Hotline.h
//  Konotor
//
//  Created by AravinthChandran on 9/7/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define HOTLINE_UNREAD_MESSAGE_COUNT @"com.freshdesk.hotline_unread_notification_count"

@class HotlineConfig, HotlineUser;

@interface Hotline : NSObject

@property(nonatomic, strong, readonly) HotlineConfig *config;

+(NSString *)SDKVersion;

/**
 *  Access the Hotline instance.
 *
 *  @discussion Using the returned shared instance, you can access all the instance methods available in Hotline.
 */
+(instancetype) sharedInstance;

/**
 *  Initialize configuration for Config.
 *
 *  @param config Hotline Configuration of type HotlineConfig
 */

-(void)initWithConfig:(HotlineConfig *)config;

-(void)showConversations:(UIViewController *)controller;

-(void)showFAQs:(UIViewController *)controller;

-(void)clearUserData;

-(void)updateUser:(HotlineUser *) user;

-(void)updateUserProperties:(NSDictionary*)props;

-(void)updateUserPropertyforKey:(NSString *) key withValue:(NSString *)value;

-(void)updateDeviceToken:(NSData *) deviceToken;

-(BOOL)isHotlineNotification:(NSDictionary *)info;

-(UIViewController*) getSolutionsControllerForEmbed;

-(UIViewController*) getConversationsControllerForEmbed;

/**
 *  Get the last updated unread messages count.
 *
 *  @discussion This method returns the last updated count of conversations which require the user's attention. This may not always be up to date.
 */
-(NSInteger)unreadCount;

/**
 *  Get the unread conversations count.
 *
 *  @discussion This method lets you asynchronously fetch the latest count of conversations that require the user's attention. It is always up to date.
 *
 *  @param completion Completion block with count.
 *
 */
-(void)unreadCountWithCompletion:(void(^)(NSInteger count))completion;

-(void)handleRemoteNotification:(NSDictionary *)info andAppstate:(UIApplicationState)appState;

@end

@interface HotlineConfig : NSObject

@property (strong, nonatomic) NSString *appID;
@property (strong, nonatomic) NSString *appKey;
@property (strong, nonatomic) NSString *domain;
@property (nonatomic, assign) BOOL voiceMessagingEnabled;
@property (nonatomic, assign) BOOL pictureMessagingEnabled;
@property (nonatomic, assign) BOOL displaySolutionsAsGrid;//Not present in Android
@property (nonatomic, assign) BOOL cameraCaptureEnabled;
@property (nonatomic, assign) BOOL notificationSoundEnabled;
@property (nonatomic, assign) BOOL agentAvatarEnabled;
@property (nonatomic, assign) BOOL showNotificationBanner;

/**
 *  Initialize Hotline.
 *
 *  @discussion In order to initialize Hotline, you'll need the three parameters mentioned above. Place the Hotline initialization code in your app delegate, preferably at the top of the application:didFinishLaunchingWithOptions method.
 *
 *  @param appKey    The App Key assigned to your app when it was created on the portal.
 *
 *  @param appSecret The App Secret assigned to your app when it was created on the portal.
 *
 */
-(instancetype)initWithAppID:(NSString*)appID andAppKey:(NSString*)appKey;


@end

@interface HotlineUser : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *phoneNumber;
@property (strong, nonatomic) NSString *externalID;
@property (strong, nonatomic) NSString *phoneCountryCode;

+(instancetype)sharedInstance;

@end