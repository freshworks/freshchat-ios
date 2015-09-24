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
//+(BOOL) isServerReachable;
+(NSURL *) getRedirectURLWithString:(NSString *) url;
+(BOOL) isSuccessResponseCode: (NSURLResponse *) response;
+ (void) SetNetworkActivityIndicator: (BOOL) isVisible;
+(NSURL *) getRedirectURLWithURL:(NSURL *) url;
+(NSString *) DownloadFile :(NSString *) httpPath;

@end


@interface KonotorUtil: NSObject
+(NSString *) GetBaseURL;
+ (NSDictionary *)deviceInfoProperties;
+(NSString*) TruncateString:(NSString *)origString withClipLength:(int) clipLength;
+(AFKonotorHTTPClient *) SingletonClient;
+ (NSString*) reversingName:(NSString *)myNameText;
//+(NSString *) ReturnURIForObject :( NSManagedObject *) object;
+(void) AlertView:(NSString *)alertviewstring FromModule:(NSString *)pModule;
+(void) PostNotificationWithName :(NSString *) notName withObject: (id) object;

+(UIBackgroundTaskIdentifier) beginBackgroundExecutionWithExpirationHandler:(SEL)expirationHandler withParameters:(id)parameter forObject:(id) object;
+(void) EndBackgroundExecutionForTask:(UIBackgroundTaskIdentifier) bgtask;
@end
