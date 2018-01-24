//
//  FDMemLogger.m
//  HotlineSDK
//
//  Created by Hrishikesh on 14/04/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FDMemLogger.h"
#import "FDUtilities.h"
#import "HLVersionConstants.h"
#import "HLMacros.h"
#import "HLAPIClient.h"
#import "HLServiceRequest.h"
#import "HLNotificationHandler.h"
#import "FDSecureStore.h"

@interface FDMemLogger ()

@property (nonatomic, strong) NSMutableArray *logList;

@end

@implementation FDMemLogger

static NSString * const LOGGER_API = @"https://xp8jwcfqkf.execute-api.us-east-1.amazonaws.com/prod/error";

+(NSString*) getSessionId{
    static NSString *sessionId;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sessionId = [FDStringUtil generateUUID];
    });
    return sessionId;
}

-(id)init{
    self = [super init];
    if(self){
        _logList = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)addMessage:(NSString *) message{
    [self.logList addObject:message];
}

-(void)addMessage:(NSString*) message withMethodName:(NSString*) methodName{
    [self addMessage:[NSString stringWithFormat:@"%@ : %@", methodName, message]];
}

-(void)addErrorInfo:(NSDictionary*) dict withMethodName:(NSString*) methodName{
    [self addMessage:[NSString stringWithFormat:@"%@ : %@", methodName, dict]];
}

-(void)addErrorInfo:(NSDictionary*) dict{
    [self addMessage:[NSString stringWithFormat:@"Error Info : %@", dict]];
}

-(NSString *)toString {
    
    NSString *pushNotifState = ([HLNotificationHandler areNotificationsEnabled]) ? @"Yes" : @"No";
    NSString *appState = nil;
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if (state == UIApplicationStateActive){
        appState = @"Active";
    }else if(state == UIApplicationStateInactive){
        appState = @"Inactive";
    }else{
        appState = @"Background";
    }
    
    NSString *userAlias = [FDUtilities currentUserAlias];
    userAlias = userAlias ? userAlias : @"NIL";
    
    BOOL isUserRegistered =  [[FDSecureStore sharedInstance] boolValueForKey:HOTLINE_DEFAULTS_IS_USER_REGISTERED];
    NSString *sessionID = [self getUserSessionId];
    
    NSDictionary *additionalInfo = @{
                                     @"Device Model" : [FDUtilities deviceModelName],
                                     @"Application state" : appState,
                                     @"User alias" : userAlias,
                                     @"Push notification enabled" : pushNotifState,
                                     @"Time stamp" : [NSDate date],
                                     @"SDK Version" : HOTLINE_SDK_VERSION,
                                     @"App Name" : [FDUtilities appName],
                                     @"deviceIosMeta" : [FDUtilities deviceInfoProperties],
                                     @"Is user registered" : isUserRegistered ? @"YES" : @"NO",
                                     @"SessionID" : sessionID ? sessionID : @"NIL"
                                     };
    
    [self addErrorInfo:additionalInfo withMethodName:@"AdditionalInfo"];
    return [self.logList componentsJoinedByString:@"\n"];
}

-(NSString *)getUserSessionId{
    return [NSString stringWithFormat:@"%@_%@", [FDMemLogger getSessionId], [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]*1000] stringValue]];
}

-(void)upload{
    
    if (self.logList.count == 0) return;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
    NSURL *url = [NSURL URLWithString:LOGGER_API];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    __block NSString *log = @"";
    dispatch_async(dispatch_get_main_queue(), ^{
        log = [self toString];
    });
    FDLog(@"***Memlogger*** Going to upload: \n %@" , log);
    request.HTTPMethod = HTTP_METHOD_POST;
    request.HTTPBody = [log dataUsingEncoding:NSUTF8StringEncoding];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            [self reset];
            FDLog(@"successfully uploaded log");
        }else{
            ALog(@"Failed  : %@",log);
            FDLog(@"Response %@", response);
        }
    }]resume];
}

-(void)reset{
    self.logList = [[NSMutableArray alloc]init];
}

+(void)sendMessage:(NSString *) message fromMethod:(NSString*) methodName{
    FDMemLogger *logger = [FDMemLogger new];
    [logger addMessage:message withMethodName:methodName];
    [logger upload];
}

@end
