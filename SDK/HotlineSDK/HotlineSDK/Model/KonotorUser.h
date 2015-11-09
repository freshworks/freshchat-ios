//
//  KonotorUser.h
//  Konotor
//
//  Created by Vignesh G on 08/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "KonotorConversation.h"

@interface KonotorUserData : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *userAlias;
@property (strong, nonatomic) NSString *appGeneratedUserID;

@end

@interface KonotorUser : NSManagedObject

@property (strong, retain) NSString *name;
@property (strong, retain) NSString *email;
@property (strong, retain) NSString *appSpecificIdentifier;
@property (strong, retain) NSString *userAlias;
@property (nonatomic) BOOL isUserCreatedOnServer;
@property (nonatomic, strong) NSSet *hasConversations;

+(void)InitUser;
+(BOOL)isUserPresent;
+(BOOL) isUserCreatedOnServer;
+(NSString *) GetUserAlias;
+(BOOL) UserCreatedOnServer;
+(KonotorUser *) GetCurrentlyLoggedInUser;
+(BOOL) CreateUserOnServerIfNotPresentandPerformSelectorIfSuccessful:(SEL)SuccessSelector withObject:(id) successObject withSuccessParameter:(id) successParameter
                                                           ifFailure:(SEL)failureSelector withObject: (id) failureObject withFailureParameter:(id) failureParameter;

+(void) setUserIdentifier: (NSString *) UserIdentifier;
+(void) setUserName: (NSString *) fullName;
+(void) setUserEmail: (NSString *) email;
+(void) setCustomUserProperty:(NSString *) value forKey: (NSString*) key;

@end