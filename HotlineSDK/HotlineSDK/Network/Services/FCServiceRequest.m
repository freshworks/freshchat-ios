//
//  HLServiceRequest.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 10/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FCServiceRequest.h"
#import "FCAPI.h"
#import <UIKit/UIKit.h>
#import "FCSecureStore.h"
#import "FCVersionConstants.h"
#import "FCStringUtil.h"

@interface FCServiceRequest ()

@property (nonatomic, strong) NSString *formBoundary;
@property (nonatomic, strong) NSMutableData *formData;
@property (nonatomic, strong, readwrite) NSURL *baseURL;
@property (nonatomic) NSStringEncoding preferredEncoding;
@property (nonatomic, strong) NSData *crlf;

@end

@implementation FCServiceRequest

-(NSURL *)getHotlineURL{
    FCSecureStore *store = [FCSecureStore sharedInstance];
    return [NSURL URLWithString:[NSString stringWithFormat:HOTLINE_USER_DOMAIN,[store objectForKey:HOTLINE_DEFAULTS_DOMAIN]]];
}

-(instancetype)initWithMethod:(NSString *)httpMethod{
    self = [self initWithBaseURL:[self getHotlineURL] andMethod:httpMethod];
   
    return self;
}

-(instancetype)initWithBaseURL:(NSURL *)baseURL andMethod:(NSString *)httpMethod{
    self = [super init];
    if (self) {
        self.URL = baseURL;
        self.baseURL = baseURL;
        self.timeoutInterval = 60;
        self.preferredEncoding = NSUTF8StringEncoding;
        UIDevice *device = [UIDevice currentDevice];
        NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
        
        NSString *userAgent = [NSString stringWithFormat:@"FC-iOS(%@)(%@)(%@)(%@)",
                               device.systemVersion, FRESHCHAT_SDK_VERSION, device.model, bundleIdentifier];
        [self setValue:userAgent forHTTPHeaderField:@"User-Agent"];
        [self setValue:FRESHCHAT_SDK_BUILD_NUMBER forHTTPHeaderField:@"X-SDK-Version-Code"];
        [self setValue:bundleIdentifier forHTTPHeaderField:@"X-App-Package-Name"];
        [self addValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [self setValue:@"iOS" forHTTPHeaderField:@"X-FC-Platform"];
        
        self.HTTPMethod = httpMethod;
        if ([httpMethod isEqualToString:HTTP_METHOD_POST] || [httpMethod isEqualToString:HTTP_METHOD_PUT]) {
            NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
            [self setValue:[NSString stringWithFormat:@"application/json; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
        }
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
    self = [self initWithBaseURL:[self getHotlineURL] andMethod:HTTP_METHOD_POST];
    if (self) {
        
        self.crlf = [FDMultipartFormCRLF dataUsingEncoding:self.preferredEncoding];
        
        //Boundary varies for every request
        self.formBoundary = FDCreateMultipartFormBoundary();
        
        self.formData = [[NSMutableData alloc]init];
        
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

-(void)addTextPart:(NSString *)text name:(NSString *)name{
    [self addPart:[text dataUsingEncoding:self.preferredEncoding] name:name];
}

-(void)addPart:(NSData *)data name:(NSString *)name{
    [self.formData appendData:[[self multipartFormInitialBoundary] dataUsingEncoding:self.preferredEncoding]];
    [self.formData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"", name]dataUsingEncoding:self.preferredEncoding]];
    [self appendContent:data];
}

-(void)addFilePart:(NSData *)data name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType{
    [self.formData appendData:[[self multipartFormInitialBoundary] dataUsingEncoding:self.preferredEncoding]];
    [self.formData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"", name, fileName]
                               dataUsingEncoding:self.preferredEncoding]];
    [self addCRLF];
    [self.formData appendData:[[NSString stringWithFormat:@"Content-Type: %@", mimeType] dataUsingEncoding:self.preferredEncoding]];
    [self appendContent:data];
}

-(void)addCRLF{
    [self.formData appendData:self.crlf];
}

-(void)appendContent:(NSData *)data{
    [self addCRLF];
    [self addCRLF];
    [self.formData appendData:data];
    [self addCRLF];
}

-(NSString *)toString{
    FCServiceRequest *serReq = [self copy];
    NSString *body = [[[NSString alloc]initWithData:self.formData encoding:self.preferredEncoding] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:serReq.URL resolvingAgainstBaseURL:false];
    NSMutableArray<NSURLQueryItem*> *queryItems = [[NSMutableArray alloc]init];
    for (NSURLQueryItem *item in components.queryItems) {
        if([item.name isEqual: @"t"]) {
            [queryItems addObject:[[NSURLQueryItem alloc]initWithName:@"t" value:@"XXXXXXXXXXX"]];
        } else {
            [queryItems addObject:[[NSURLQueryItem alloc]initWithName:item.name value:item.value]];
        }
    }
    [components setQueryItems:queryItems];
    serReq.URL = components.URL;
    return [NSString stringWithFormat:@"HEADERS : %@ REQUEST: %@ HTTP-BODY:%@", [self allHTTPHeaderFields] , serReq, body];
}

@end