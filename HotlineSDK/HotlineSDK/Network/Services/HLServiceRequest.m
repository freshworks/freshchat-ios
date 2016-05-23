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
#import "FDSecureStore.h"

@interface HLServiceRequest ()

@property(nonatomic, strong, readwrite) NSURL *baseURL;

@end

@implementation HLServiceRequest

-(NSURL *)getHotlineURL{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    return [NSURL URLWithString:[NSString stringWithFormat:HOTLINE_USER_DOMAIN,[store objectForKey:HOTLINE_DEFAULTS_DOMAIN]]];
}

-(instancetype)initWithMethod:(NSString *)httpMethod{
    self = [self initWithBaseURL:[self getHotlineURL]];
    if (self) {
        self.HTTPMethod = httpMethod;
        if ([httpMethod isEqualToString:HTTP_METHOD_POST] || [httpMethod isEqualToString:HTTP_METHOD_PUT]) {
            NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
            [self setValue:[NSString stringWithFormat:@"application/json; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
        }
    }
    return self;
}

-(instancetype)initMultipartFormRequest{
    self = [self initWithBaseURL:[self getHotlineURL]];
    if (self) {
        self.HTTPMethod = HTTP_METHOD_POST;
    }
    return self;
}


-(instancetype)initWithBaseURL:(NSURL *)baseURL{
    self = [super init];
    if (self) {
        self.URL = baseURL;
        self.baseURL = baseURL;
        self.timeoutInterval = 60;

        NSString *userAgent = [NSString stringWithFormat:@"%@ %@",[UIDevice currentDevice].systemName,[UIDevice currentDevice].systemVersion];
        [self setValue:userAgent forHTTPHeaderField:@"User-Agent"];
        [self addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    }
    return self;
}

-(void)setRelativePath:(NSString *)path andURLParams:(NSArray *)params{
    NSMutableString *string = [NSMutableString new];

    if (path) {
        [string appendString:path];
    }
    
    if (params) {
        [string appendString:@"?"];
        for (int i=0; i<params.count; i++) {
            NSString *param = params[i];
            [string appendString:[NSString stringWithFormat:@"%@&",param]];
        }
    }
    
    self.URL = [NSURL URLWithString:string relativeToURL:self.baseURL];
}

-(void)setBody:(NSData *)body{
    self.HTTPBody = body;
    [self setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[body length]] forHTTPHeaderField:@"Content-Length"];
}

-(void)appendPartWithFormData:(NSData *)data name:(NSString *)name{
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"", name] forKey:@"Content-Disposition"];
    
}

-(void)appendPartWithFileData:(NSData *)data name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType{
    
}

- (NSString *)boundaryString{
    NSString *UUID = [[NSUUID UUID] UUIDString];
    return [NSString stringWithFormat:@"Boundary-%@", UUID];
}

@end