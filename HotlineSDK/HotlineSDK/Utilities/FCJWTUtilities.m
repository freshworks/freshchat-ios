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

@implementation FCJWTUtilities

+ (NSDictionary *) getJWTUserPayloadFromToken : (NSString *) token{
    
    
    
    if(!token.length) return @{};
    NSArray *tokenStucture = [token componentsSeparatedByString:@"."];
    
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

+ (BOOL) isUserAuthEnabled {
    return ([FCRemoteConfig sharedInstance].userAuthConfig.isjwtAuthEnabled
            && [FCRemoteConfig sharedInstance].userAuthConfig.isStrictModeEnabled);
}

+ (BOOL) isJWTTokenExpired {
    if([FreshchatUser sharedInstance].jwtToken){
        NSDictionary *jwtTokenInfo = [self getJWTUserPayloadFromToken:[FreshchatUser sharedInstance].jwtToken];
        if([jwtTokenInfo objectForKey:@"iat"] && [jwtTokenInfo objectForKey:@"exp"]){
             NSTimeInterval currentRequestTime = [FCUtilities getCurrentTimeInMillis];
            if(currentRequestTime > ([[jwtTokenInfo objectForKey:@"exp"] longValue] * ONE_SECONDS_IN_MS)){
                return true;
            }
        }
    }
    return false;
}

+ (NSString*) getReferenceID: (NSString *) token {
    if(token){
        NSDictionary *jwtTokenInfo = [self getJWTUserPayloadFromToken:token];
        if([jwtTokenInfo objectForKey:@"reference_id"]){
            return [jwtTokenInfo objectForKey:@"reference_id"];
        }
    }
    return nil;
}

+ (NSString*) getAliasFrom: (NSString *) token {
    if(token){
        NSDictionary *jwtTokenInfo = [self getJWTUserPayloadFromToken:token];
        if([jwtTokenInfo objectForKey:@"freshchat_uuid"]){
            return [jwtTokenInfo objectForKey:@"freshchat_uuid"];
        }
    }
    return nil;
}


+ (BOOL) hasValidRefIdForJWTToken :(NSString *) token {
    NSDictionary *jwtTokenInfo = [self getJWTUserPayloadFromToken:[FreshchatUser sharedInstance].jwtToken];
    if([jwtTokenInfo objectForKey:@"reference_id"] != nil){
        return true;
    }
    return false;
}

@end
