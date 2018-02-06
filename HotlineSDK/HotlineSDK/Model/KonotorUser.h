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

@class KonotorCustomProperty;

NS_ASSUME_NONNULL_BEGIN

@interface KonotorUser : NSManagedObject

@property (nullable, nonatomic, retain) NSString *appSpecificIdentifier;
@property (nullable, nonatomic, retain) NSString *email;
@property (nullable, nonatomic, retain) NSNumber *isUserCreatedOnServer;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *phoneNumber;
@property (nullable, nonatomic, retain) NSString *countryCode;
@property (nullable, nonatomic, retain) NSString *userAlias;
@property (nullable, nonatomic, retain) KonotorCustomProperty *hasProperties;

+(void)storeUserInfo:(FreshchatUser *)userInfo;
+(KonotorUser *)getUser;
+(void) removeUserInfo;

@end

NS_ASSUME_NONNULL_END
