//
//  FCJWTUtilities.m
//  FreshchatSDK
//
//  Created by Harish Kumar on 09/10/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import "FCJWTUtilities.h"
#import "FCRemoteConfig.h"

@implementation FCJWTUtilities

+ (NSDictionary *) getJWTUserPayloadFromToken : (NSString *) token{
    
    if(!token.length) return 0;
    NSArray *tokenStucture = [token componentsSeparatedByString:@"."];
    
    NSString *tokenPayload = [tokenStucture objectAtIndex:1];
    NSString *pay = [tokenPayload stringByPaddingToLength:[tokenPayload length]+(tokenPayload.length)%4 withString:@"=" startingAtIndex:0];
    
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:pay options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSString *decodedString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
    NSDictionary *payloadDict = [NSJSONSerialization JSONObjectWithData:[decodedString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
    return payloadDict;
}

+ (BOOL) isUserAuthEnabled {
    return ([FCRemoteConfig sharedInstance].userAuthConfig.isjwtAuthEnabled && [FCRemoteConfig sharedInstance].userAuthConfig.isStrictModeEnabled);
}

+ (BOOL) isExpiredJWTToken {
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:[FCUserDefaults getObjectForKey:CONFIG_RC_LAST_API_FETCH_INTERVAL_TIME]];
}

@end
