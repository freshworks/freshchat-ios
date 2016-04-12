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

@interface FDMemLogger ()

@property NSMutableArray *logList;

@end

@implementation FDMemLogger

-(id)init{
    self = [super init];
    if(self){
        _logList = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)addMessage:(NSString *) message{
    [_logList addObject:message];
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
    NSDictionary *additionalInfo = @{
                                     @"Time stamp" : [NSDate date],
                                     @"SDK Version" : HOTLINE_SDK_VERSION,
                                     @"Device Info" : [FDUtilities deviceInfoProperties]
                                     };
    
    [self addErrorInfo:additionalInfo withMethodName:@"AdditionalInfo"];

    
    NSString *log = [self.logList componentsJoinedByString:@"\n"];
    return log;
}

-(void)upload{
    NSString *log = [self toString];
    FDLog(@"Going to upload : %@" , log);
    NSData *postData = [log dataUsingEncoding:NSUTF8StringEncoding];
    NSString *logglyURL = @"https://xp8jwcfqkf.execute-api.us-east-1.amazonaws.com/prod/error";
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:[NSURL URLWithString:logglyURL]];
    request.HTTPBody = postData;
    request.HTTPMethod = HTTP_METHOD_POST;
    [apiClient request:request withHandler:^(FDResponseInfo *responseInfo,NSError *error) {
        if (!error) {
            FDLog(@"successfully uploaded log");
        }else{
            NSLog(@"Failed  : %@",log);
            FDLog(@"Response %@", responseInfo.response);
        }
    }];
}

@end