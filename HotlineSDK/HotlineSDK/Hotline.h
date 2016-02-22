//
//  Hotline.h
//  Konotor
//
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//
//  Contact support@hotline.io

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class HotlineConfig, HotlineUser;

@interface HotlineConfig : NSObject

/*
 * App ID of your App. This is used to authenticate the SDK for your app. Please check with your Admin SDK Integration settings.
 */
@property (strong, nonatomic) NSString *appID;
/*
 * App Key of your App. This is used to authenticate the SDK for your app. Please check with your Admin SDK Integration settings.
 */
@property (strong, nonatomic) NSString *appKey;
/*
 * Domain for Hotline. This defaults to app.hotline.io. If you were using Konotor SDK earlier please set it to app.konotor.com.
 */
@property (strong, nonatomic) NSString *domain;
/*
 * Enable/disable voice messages. When enabled user can record and send audio attachments on the chat. Default NO.
 */
@property (nonatomic, assign) BOOL voiceMessagingEnabled;
/*
 * Enable/disable picture messages. When enabled users can send picture attachments on the chat. Default YES.
 */
@property (nonatomic, assign) BOOL pictureMessagingEnabled;
/*
 * Option to Switch between Grid and List. Show FAQ categories as a List. Default YES ( Grid View )
 */
@property (nonatomic, assign) BOOL displayFAQsAsGrid;
/*
 * Allow the user to attach pictures by using the camera. Default YES.
 */
@property (nonatomic, assign) BOOL cameraCaptureEnabled;
/*
 * Enable alert sound when a notification is received. Default YES.
 */
@property (nonatomic, assign) BOOL notificationSoundEnabled;
/*
 * Show/Hide Agent Avatar on the Chat. It is enabled by default. Default YES
 */
@property (nonatomic, assign) BOOL agentAvatarEnabled;
/*
 * Enable/Disable Notification banner when a support message is received. Default YES
 */
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

/**
 *  Present the Conversations / Chat to the user.
 *
 *  @discussion This method lets you launch and present the Channels list to the user. The user directly lands in the Conversation view if there is only one channel.
 *
 *  @param controller This is essentially the view controller from where you're attempting to present the view.
 *
 */
-(void)showConversations:(UIViewController *)controller;
/**
 *  Present the FAQs to the user.
 *
 *  @discussion This method lets you launch the FAQ view.
 *
 *  @param controller This is essentially the view controller from where you're attempting to present the view.
 *
 */
-(void)showFAQs:(UIViewController *)controller;
/**
 *  Clear User Data
 *
 *  @discussion Use this function when your user needs to log out of the app . This will clean up all the data associated with the SDK for the user.
 *
 */
-(void)clearUserData;
/**
 *  Update user Info
 *
 *  @discussion Allows you to update the user info such as Name, Email, Phone, Country Code and any Identifier. Identifier provided with the user needs to be an unique value that your App can use to identify the user.
 *
 *  @param user User instance with the values to be updated.
 *
 */
-(void)updateUser:(HotlineUser *) user;
/**
 *  Update User properties
 *
 *  @discussion Allows you tag your users with some Key Value pairs . The user properties associated here will be available on the Dashboard for the Agent.
 *
 *  @param props An NSDictionary containing the Properties for the User.
 *
 */
-(void)updateUserProperties:(NSDictionary*)props;
/**
 *  Update user property
 *
 *  @discussion Use this method to update a single property for the user. Prefer updateUserProperties whereever possible.
 *
 *  @param key Property name
 *
 *  @param value Property value
 *
 */
-(void)updateUserPropertyforKey:(NSString *) key withValue:(NSString *)value;
/**
 *  Update the APNS device token
 *
 *  @discussion Update the APNS device token when APNS registration is successful. The SDK uses this to send push notification when there are replies from the agent.
 *
 *  @param deviceToken APNS device token
 *
 */
-(void)updateDeviceToken:(NSData *) deviceToken;
/**
 *  Check if a Push Notification was from Hotline
 *
 *  @discussion Checks if the dictionary received on a Push Notification originated from hotline. Use this in conjunction with handleRemoteNotification
 *
 *  @param info Dictionary received in didReceiveRemoteNotification for Push Notification.
 */
-(BOOL)isHotlineNotification:(NSDictionary *)info;
/**
 *  Handle the Hotline message push Notification
 *
 *  @discussion Needs to be called when a push notification is received from Hotline. This will present the conversation or shows a drop down notification.
 *
 *  @param info Dictionary received in didReceiveRemoteNotification for Push Notification.
 *  
 *  @param appState
 */
-(void)handleRemoteNotification:(NSDictionary *)info andAppstate:(UIApplicationState)appState;
/**
 *  Get an Embeddable controller for FAQs
 *
 *  @discussion Return a controller with FAQs that can be embedded in other Controllers (e.g. in a UITabBarController )
 *
 */
-(UIViewController*) getFAQsControllerForEmbed;
/**
 *  Get an Embeddable controller for Conversations
 *
 *  @discussion Return a controller with Chats that can be embedded in other Controllers (e.g. in a UITabBarController )
 *
 */
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
 *  @discussion This method lets you asynchronously fetch the latest count of conversations that require the user's attention. It is updated with a 2 min interval.
 *
 *  @param completion Completion block with count.
 *
 */
-(void)unreadCountWithCompletion:(void(^)(NSInteger count))completion;



@end

@interface HotlineUser : NSObject

/*
 * User name
 */
@property (strong, nonatomic) NSString *name;
/*
 * User email
 */
@property (strong, nonatomic) NSString *email;
/*
 * Phone Number - Preferably Mobile Number
 */
@property (strong, nonatomic) NSString *phoneNumber;
/*
 * Phone Country Code e.g +91 for India
 */
@property (strong, nonatomic) NSString *phoneCountryCode;
/*
 * Unique identifier for the user.
 */
@property (strong, nonatomic) NSString *externalID;


/*
 * Access the user info. If update user was called earlier, the instance would contain the persisted values.
 */
+(instancetype)sharedInstance;

@end