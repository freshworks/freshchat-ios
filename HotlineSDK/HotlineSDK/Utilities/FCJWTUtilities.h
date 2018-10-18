//
//  FCJWTUtilities.h
//  FreshchatSDK
//
//  Created by Harish Kumar on 09/10/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FCJWTUtilities : NSObject

+ (NSDictionary *) getJWTUserPayloadFromToken : (NSString *) token;

+ (BOOL) isUserAuthEnabled;

+ (BOOL) isJWTTokenExpired;

+ (BOOL) hasValidRefIdForJWTToken :(NSString *) token;

+ (NSString*) getReferenceID: (NSString *) token;

+ (NSString*) getAliasFrom: (NSString *) token;

+(BOOL) isJwtWaitingToAuth;

+(NSString *) getPendingJWTToken;

+(void) setPendingJWTToken : (NSString *) token;

+(void) removePendingJWTToken;

+(void) setPendingRestoreJWTToken : (NSString *) token;

+ (void) removePendingRestoreJWTToken;

+ (NSString *) getPendingRestoreJWTToken;

@end

