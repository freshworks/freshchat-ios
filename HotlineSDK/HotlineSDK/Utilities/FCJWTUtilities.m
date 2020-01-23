//
//  FCJWTUtilities.m
//  FreshchatSDK
//
//  Created by Harish Kumar on 09/10/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import "FCJWTUtilities.h"
#import "FCRemoteConfig.h"
#import "FCUtilities.h"
#import "FCUserDefaults.h"
#import "FCSecureStore.h"
#import "FCJWTAuthValidator.h"
#import "FCMacros.h"
#import "FCUserUtil.h"
#import "FCUsers.h"
#import "FCReachabilityManager.h"

@implementation FCJWTUtilities

+ (NSDictionary *) getJWTUserPayloadFromToken : (NSString *) jwtIdToken{
    if(!jwtIdToken.length) return @{};
    NSArray *tokenStucture = [jwtIdToken componentsSeparatedByString:@"."];
    
    NSString *tokenPayload = [tokenStucture objectAtIndex:1];
    int modPayload = tokenPayload.length % 4;
    int repeatCount= 0;
    if(modPayload!=0) {
        repeatCount = 4-modPayload;
    }
    
    NSString *pay = [tokenPayload stringByPaddingToLength:[tokenPayload length]+repeatCount withString:@"=" startingAtIndex:0];
    
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:pay options:NSDataBase64DecodingIgnoreUnknownCharacters];
      NSString *decodedString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
    NSDictionary *payloadDict = [NSJSONSerialization JSONObjectWithData:[decodedString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
    return payloadDict;
}

+ (BOOL) isValidityExpiedForJWTToken :(NSString*) jwtIdToken {
    if(jwtIdToken.length > 0){
        NSDictionary *jwtTokenInfo = [self getJWTUserPayloadFromToken:jwtIdToken];
        if([jwtTokenInfo objectForKey:@"exp"]){
            NSTimeInterval currentRequestTime = [FCUtilities getCurrentTimeInMillis];
            if(currentRequestTime > ([[jwtTokenInfo objectForKey:@"exp"] longValue] * ONE_SECONDS_IN_MS)){
                return TRUE;
            }
        }
    }
    return FALSE;
}

+ (BOOL) canProgressSetUserForToken : (NSString *) jwtIdToken {
    
    if(![[FCRemoteConfig sharedInstance] isUserAuthEnabled] && [FCUtilities isRemoteConfigFetched]){
        ALog(@"Freshchat API Error : setUserWithIdToken is valid only in Strict mode!!");
        [FCJWTUtilities removePendingJWTToken]; //Remove pending state if non JWT called before call
        return FALSE;
    }
    
    
    if(trimString(jwtIdToken).length == 0){
        return FALSE;
    }
    else {
        //Empty Alias
        if ([FCJWTUtilities getAliasFrom: jwtIdToken] == nil) {
            ALog(@"Freshchat API : Empty Alias Found");
            return FALSE;
        }

        //Different Alias
        if(![[FCJWTUtilities getAliasFrom: jwtIdToken] isEqualToString: [[Freshchat sharedInstance] getFreshchatUserId]]) {
            ALog(@"Freshchat API : Different Alias Found");
            return FALSE;
        }
        
        //Same token
        if([jwtIdToken isEqualToString:[FreshchatUser sharedInstance].jwtToken]) {
            ALog(@"Freshchat API : Same Payload");
            return FALSE;
        }
        
        //Token expiry
        if([FCJWTUtilities isValidityExpiedForJWTToken:jwtIdToken]){
            ALog(@"Freshchat API : Expired JWT Token");
            return FALSE;
        }
        
        //User registered
        if([FCUserUtil isUserRegistered]) {
             [FCUsers updateUserWithIdToken:jwtIdToken];
             [FCUtilities initiatePendingTasks];
             return FALSE;
         }
        
    }
    return TRUE;
}

+ (BOOL) canProgressUserRestoreForToken : (NSString *) jwtIdToken{
    
    if(![[FCRemoteConfig sharedInstance] isUserAuthEnabled] && [FCUtilities isRemoteConfigFetched]){
        ALog(@"Freshchat API Error : restoreUserWithIdToken is valid only in Strict mode!!");
        [FCJWTUtilities removePendingRestoreJWTToken]; //Remove pending state if non JWT called before call
        return FALSE;
    }
    
    if(trimString(jwtIdToken).length == 0){
        ALog(@"Freshchat : JWT token missing for identifyUser API!");
        [FCJWTUtilities removePendingRestoreJWTToken];//Remove if it is called by non JWT user before RC
        return FALSE;
    } else {
        if([jwtIdToken isEqualToString:[FreshchatUser sharedInstance].jwtToken]) {
            ALog(@"Freshchat API : Same Payload");
            return FALSE;
        }
    }
    
    return TRUE;
}

+ (NSString*) getReferenceID: (NSString *) jwtIdToken {
    if(jwtIdToken){
        NSDictionary *jwtTokenInfo = [self getJWTUserPayloadFromToken:jwtIdToken];
        if([jwtTokenInfo objectForKey:@"reference_id"]){
            return [jwtTokenInfo objectForKey:@"reference_id"];
        }
    }
    return nil;
}

+ (NSString*) getAliasFrom: (NSString *) jwtIdToken {
    if(jwtIdToken){
        NSDictionary *jwtTokenInfo = [self getJWTUserPayloadFromToken:jwtIdToken];
        if([jwtTokenInfo objectForKey:@"freshchat_uuid"]){
            return [jwtTokenInfo objectForKey:@"freshchat_uuid"];
        }
    }
    return nil;
}

+ (BOOL) hasValidRefIdForJWTToken :(NSString *) jwtIdToken {
    NSDictionary *jwtTokenInfo = [self getJWTUserPayloadFromToken:[FreshchatUser sharedInstance].jwtToken];
    if([jwtTokenInfo objectForKey:@"reference_id"] != nil){
        return true;
    }
    return false;
}

+ (void) setTokenInitialState{
    if([[FCRemoteConfig sharedInstance] isUserAuthEnabled]
       && ([FreshchatUser sharedInstance].jwtToken == nil && ![[FreshchatUser sharedInstance].jwtToken isEqualToString:@""]) ){
        [[FCJWTAuthValidator sharedInstance] updateAuthState:TOKEN_NOT_SET];
    }
}

+(NSString *) getPendingJWTToken {
    return [[FCSecureStore sharedInstance] objectForKey:FRESHCHAT_DEFAULTS_USER_VERIFICATION_PENDING_TOKEN];
}

+(void) setPendingJWTToken : (NSString *) jwtIdToken {
    [[FCSecureStore sharedInstance] setObject:jwtIdToken forKey:FRESHCHAT_DEFAULTS_USER_VERIFICATION_PENDING_TOKEN];
}

+(void) removePendingJWTToken {
    [[FCSecureStore sharedInstance] removeObjectWithKey:FRESHCHAT_DEFAULTS_USER_VERIFICATION_PENDING_TOKEN];
}

+ (void) setPendingRestoreJWTToken : (NSString *) jwtIdToken {
    [[FCSecureStore sharedInstance] setObject:jwtIdToken forKey:FRESHCHAT_DEFAULTS_USER_AUTH_ID_RESTORE_PENDING_TOKEN];
}

+ (void) removePendingRestoreJWTToken {
    [[FCSecureStore sharedInstance] removeObjectWithKey:FRESHCHAT_DEFAULTS_USER_AUTH_ID_RESTORE_PENDING_TOKEN];
}

+ (NSString *) getPendingRestoreJWTToken {
    return [[FCSecureStore sharedInstance] objectForKey:FRESHCHAT_DEFAULTS_USER_AUTH_ID_RESTORE_PENDING_TOKEN];
}

+ (void) performPendingJWTTasks {
    if(![[FCReachabilityManager sharedInstance] isReachable]) return;
    
    if([[FCRemoteConfig sharedInstance] isUserAuthEnabled] &&
       [FCJWTUtilities getPendingJWTToken]) {
        [[Freshchat sharedInstance] setUserWithIdToken : [FCJWTUtilities getPendingJWTToken]];
        return;
    }
    
    if([[FCRemoteConfig sharedInstance] isUserAuthEnabled] &&
       [FCJWTUtilities getPendingRestoreJWTToken]) {
        [[Freshchat sharedInstance] restoreUserWithIdToken:[FCJWTUtilities getPendingRestoreJWTToken]];
        return;
    }
}

+ (BOOL) isJWTTokenInvalid {
    return ([[FCRemoteConfig sharedInstance] isUserAuthEnabled] && ![self hasValidTokenState]) ? TRUE : FALSE;
}

+ (BOOL) hasInvalidTokenState {
    return ([[FCJWTAuthValidator sharedInstance] getDefaultJWTState] == TOKEN_INVALID);
}

+ (BOOL) hasValidTokenState {
    return ([[FCJWTAuthValidator sharedInstance] getDefaultJWTState] == TOKEN_VALID);
}

+ (BOOL) compareAlias:(NSString *)str1 str2:(NSString *)str2 {
    return ([[FCJWTUtilities getAliasFrom: str1] isEqualToString:
             [FCJWTUtilities getAliasFrom: str2]]);
}

@end
