//
//  FCJWTUtilities.h
//  FreshchatSDK
//
//  Created by Harish Kumar on 09/10/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FCJWTUtilities : NSObject

+ (NSDictionary *) getJWTUserPayloadFromToken : (NSString *) jwtIdToken;

+ (BOOL) isValidityExpiedForJWTToken :(NSString*) jwtIdToken;

+ (BOOL) hasValidRefIdForJWTToken :(NSString *) jwtIdToken;

+ (BOOL) canProgressSetUserForToken : (NSString *) jwtIdToken;

+ (BOOL) canProgressUserRestoreForToken : (NSString *) jwtIdToken;

+ (NSString*) getReferenceID: (NSString *) jwtIdToken;

+ (NSString*) getAliasFrom: (NSString *) jwtIdToken;

+(BOOL) isJwtWaitingToAuth;

+(NSString *) getPendingJWTToken;

+(void) setPendingJWTToken : (NSString *) jwtIdToken;

+(void) removePendingJWTToken;

+(void) setPendingRestoreJWTToken : (NSString *) jwtIdToken;

+ (void) removePendingRestoreJWTToken;

+ (NSString *) getPendingRestoreJWTToken;

+ (void) setTokenInitialState;

+ (void) performPendingJWTTasks;

+ (BOOL) compareAlias:(NSString *)str1 str2:(NSString *)str2;

+ (BOOL) isJWTTokenInvalid;

@end

