//
//  Hotline.h
//  Konotor
//
//  Created by AravinthChandran on 9/7/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class HotlineConfig, HotlineUser;

@interface Hotline : NSObject

@property(nonatomic) BOOL displaySolutionsAsGrid;

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

-(void)initWithConfig:(HotlineConfig *)config andUser:(HotlineUser *)user;

-(void)updateUser:(HotlineUser *)user;

-(void)setCustomUserPropertyForKey:(NSString *)key withValue:(NSString *)value;

-(void)presentFeedback:(UIViewController *)controller;

-(void)presentSolutions:(UIViewController *)controller;

-(void)clearUserData;

-(void)addDeviceToken:(NSData *) deviceToken;

-(void)handleRemoteNotification:(NSDictionary *)notification;

@end


@interface HotlineConfig : NSObject

@property (strong, nonatomic) NSString *appID;
@property (strong, nonatomic) NSString *appKey;
@property (strong, nonatomic) NSString *domain;

/**
 *  Initialize Hotline.
 *
 *  @discussion In order to initialize Hotline, you'll need the three parameters mentioned above. Place the Hotline initialization code in your app delegate, preferably at the top of the application:didFinishLaunchingWithOptions method.
 *
 *  @param domain    The domain name for your portal.
 *
 *  @param appKey    The App Key assigned to your app when it was created on the portal.
 *
 *  @param appSecret The App Secret assigned to your app when it was created on the portal.
 *
 */
-(instancetype)initWithDomain:(NSString*)domain withAppID:(NSString*)appID andAppKey:(NSString*)appKey;

@end

@interface HotlineUser : NSObject

@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *emailAddress;
@property (strong, nonatomic) NSString *phoneNumber;
@property (strong, nonatomic) NSString *externalID;

@end