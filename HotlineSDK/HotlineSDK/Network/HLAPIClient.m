//
//  HLAPIClient.m
//  
//
//  Created by Aravinth Chandran on 21/09/15.
//
//

#import "HLAPIClient.h"

@interface HLAPIClient ()

@property(nonatomic, strong) NSURLSession *session;

@end

@implementation HLAPIClient

+(id)sharedInstance{
    static HLAPIClient *sharedInstance = nil;
    static dispatch_once_t oncetoken;
    dispatch_once(&oncetoken,^{
        sharedInstance = [[HLAPIClient alloc]init];
    });
    return sharedInstance;
}

-(instancetype)init{
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        self.session = [NSURLSession sessionWithConfiguration:configuration];
    }
    return self;
}

-(NSURLSessionDataTask *)request:(NSURLRequest *)request withHandler:(HLNetworkCallback)handler{
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
        FDResponseInfo *responseInfo = [[FDResponseInfo alloc]initWithResponse:response];
        responseInfo.responseHTTPBody = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        
        if (statusCode >= 400) {
            NSDictionary *info = @{ @"Status code" : [NSString stringWithFormat:@"%ld", (long)statusCode] };
            error = [NSError errorWithDomain:@"Request failed" code:statusCode userInfo:info];
            if (handler) handler(responseInfo,error);
        }else{
            if (!error) {
                if (handler) handler(responseInfo,nil);
            }else{
                if (handler) handler(responseInfo,error);
            }
        }
        
    }];
    [task resume];
    return task;
}

@end