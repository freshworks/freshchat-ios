//
//  KonotorUtil.h
//  Konotor
//
//  Created by Vignesh G on 16/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"
#import <UIKit/UIApplication.h>

@interface KonotorNetworkUtil : AFKonotorHTTPClient

+ (KonotorNetworkUtil *) getHTTPClient;
- (id)initWithBaseURL:(NSURL *)url;
+(BOOL) isSuccessResponseCode: (NSURLResponse *) response;
+ (void) SetNetworkActivityIndicator: (BOOL) isVisible;

@end

@interface KonotorUtil: NSObject
+(NSString *) GetBaseURL;
+ (NSDictionary *)deviceInfoProperties;
+(AFKonotorHTTPClient *) SingletonClient;
+(void) AlertView:(NSString *)alertviewstring FromModule:(NSString *)pModule;
+(void) PostNotificationWithName :(NSString *) notName withObject: (id) object;
+(UIBackgroundTaskIdentifier) beginBackgroundExecutionWithExpirationHandler:(SEL)expirationHandler withParameters:(id)parameter forObject:(id) object;
+(void) EndBackgroundExecutionForTask:(UIBackgroundTaskIdentifier) bgtask;

@end