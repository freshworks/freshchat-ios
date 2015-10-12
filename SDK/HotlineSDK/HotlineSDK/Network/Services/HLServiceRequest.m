//
//  HLServiceRequest.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 10/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "HLServiceRequest.h"
#import "HLAPI.h"
#import <UIKit/UIKit.h>

@interface HLServiceRequest ()

@property(nonatomic, strong, readwrite) NSURL *baseURL;

@end

@implementation HLServiceRequest

-(instancetype)initWithBaseURL:(NSURL *)baseURL{
    self = [super init];
    if (self) {
        self.baseURL = baseURL;
        self.stringEncoding = NSUTF8StringEncoding;
        self.timeoutInterval = 30;
        [self setDefaultHTTPHeaders];
    }
    return self;
}

-(void)setDefaultHTTPHeaders{
    NSString *userAgent = [NSString stringWithFormat:@"%@ %@",[UIDevice currentDevice].systemName,[UIDevice currentDevice].systemVersion];
    [self setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    [self setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
}

-(void)setRelativePath:(NSString *)path andURLParams:(NSString *)params{
    NSMutableString *string = [NSMutableString new];

    if (path) {
        [string appendString:path];
    }
    
    if (params) {
        [string appendString:[NSString stringWithFormat:@"?%@",params]];
    }
    
    self.URL = [NSURL URLWithString:string relativeToURL:self.baseURL];
}

@end