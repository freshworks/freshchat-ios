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
    //TODO: Send it to loggly
}

@end