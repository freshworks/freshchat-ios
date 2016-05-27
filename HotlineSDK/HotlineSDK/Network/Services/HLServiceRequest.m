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

@property (nonatomic, strong) NSString *formBoundary;
@property (nonatomic, strong) NSMutableData *formData;
@property (nonatomic, strong, readwrite) NSURL *baseURL;
@property (nonatomic) NSStringEncoding *preferredEncoding;

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

-(instancetype)initWithBaseURL:(NSURL *)baseURL{
    self = [super init];
    if (self) {
        self.URL = baseURL;
        self.baseURL = baseURL;
        self.timeoutInterval = 60;
        self.preferredEncoding = NSUTF8StringEncoding;

        NSString *userAgent = [NSString stringWithFormat:@"%@ %@",[UIDevice currentDevice].systemName,[UIDevice currentDevice].systemVersion];
        [self setValue:userAgent forHTTPHeaderField:@"User-Agent"];
        [self addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    }
    return self;
}

static NSString * FDCreateMultipartFormBoundary() {
    return [NSString stringWithFormat:@"Boundary+%08X%08X", arc4random(), arc4random()];
}

static NSString * const FDMultipartFormCRLF = @"\r\n";

-(NSString *)multipartFormInitialBoundary{
    return [NSString stringWithFormat:@"--%@%@", self.formBoundary, FDMultipartFormCRLF];
}

-(NSString *)multipartFormFinalBoundary{
    return [NSString stringWithFormat:@"%@--%@--%@", FDMultipartFormCRLF, self.formBoundary, FDMultipartFormCRLF];
}

-(instancetype)initMultipartFormRequestWithBody:(void (^)(id <HLMultipartFormData> formData))block{
    self = [self initWithBaseURL:[self getHotlineURL]];
    if (self) {
        
        //Boundary varies for every request
        self.formBoundary = FDCreateMultipartFormBoundary();
        
        self.formData = [[NSMutableData alloc]init];
        
        self.HTTPMethod = HTTP_METHOD_POST;
        
        [self setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", self.formBoundary] forHTTPHeaderField:@"Content-Type"];

        if (block) block((id <HLMultipartFormData>)self);

        [self.formData appendData:[[self multipartFormFinalBoundary] dataUsingEncoding:self.preferredEncoding]];
        
        self.HTTPBody = self.formData;
        
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
}

#pragma mark Protocol: <HLMultipartFormData>

-(void)appendText:(NSString *)text name:(NSString *)name{
    [self appendPartWithFormData:[text dataUsingEncoding:self.preferredEncoding] name:name];
}

-(void)appendPartWithFormData:(NSData *)data name:(NSString *)name{
    [self.formData appendData:[[self multipartFormInitialBoundary] dataUsingEncoding:self.preferredEncoding]];
    [self.formData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"", name]dataUsingEncoding:self.preferredEncoding]];
    [self appendData:data];
}

-(void)appendPartWithFileData:(NSData *)data name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType{
    [self.formData appendData:[[self multipartFormInitialBoundary] dataUsingEncoding:self.preferredEncoding]];
    [self.formData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"", name, fileName]
                               dataUsingEncoding:self.preferredEncoding]];
    [self.formData appendData:[FDMultipartFormCRLF dataUsingEncoding:self.preferredEncoding]];
    [self.formData appendData:[[NSString stringWithFormat:@"Content-Type: %@", mimeType] dataUsingEncoding:self.preferredEncoding]];
    [self appendData:data];
}

-(void)appendData:(NSData *)data{
    [self.formData appendData:[FDMultipartFormCRLF dataUsingEncoding:self.preferredEncoding]];
    [self.formData appendData:[FDMultipartFormCRLF dataUsingEncoding:self.preferredEncoding]];
    [self.formData appendData:data];
    [self.formData appendData:[FDMultipartFormCRLF dataUsingEncoding:self.preferredEncoding]];
}

@end