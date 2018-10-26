//
//  KonotorUser.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 15/02/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FreshchatSDK.h"

@class FCUserProperties;

NS_ASSUME_NONNULL_BEGIN

@interface FCUsers : NSManagedObject

@property (nullable, nonatomic, retain) NSString *appSpecificIdentifier;
@property (nullable, nonatomic, retain) NSString *email;
@property (nullable, nonatomic, retain) NSNumber *isUserCreatedOnServer;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *phoneNumber;
@property (nullable, nonatomic, retain) NSString *countryCode;
@property (nullable, nonatomic, retain) NSString *userAlias;
@property (nullable, nonatomic, retain) FCUserProperties *hasProperties;

+(void)storeUserInfo:(FreshchatUser *)userInfo;
+(FCUsers *)getUser;
+(void) removeUserInfo;
+ (void) updateUserWithIdToken : (NSString *) jwtIdToken;

@end

NS_ASSUME_NONNULL_END
