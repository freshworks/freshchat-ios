//
//  HLAPIClient.m
//  
//
//  Created by Aravinth Chandran on 21/09/15.
//
//

#import "HLAPIClient.h"
#import "FDMemLogger.h"
#import "FDUtilities.h"

@interface HLAPIClient ()

@property(nonatomic, strong) NSMutableArray *loggedAPICalls;
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
        self.loggedAPICalls = [[NSMutableArray alloc]init];
    }
    return self;
}

-(NSURLSessionDataTask *)request:(HLServiceRequest *)request withHandler:(HLNetworkCallback)handler{
    if([FDUtilities isAccountDeleted]){
        return 0;
    }
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
        
        FDResponseInfo *responseInfo = [[FDResponseInfo alloc]initWithResponse:response andHTTPBody:data];
        if (statusCode >= 400) {
            if(statusCode == 410){//For GDPR compliance
                [FDUtilities handleGDPRForResponse:responseInfo];
            }else{//Do not add failed logs for deleted user or account into loggly
                [self logRequest:request response:responseInfo];
            }
            NSDictionary *info = @{ @"Status code" : [NSString stringWithFormat:@"%ld", (long)statusCode] };
            if (handler) handler(responseInfo,[NSError errorWithDomain:@"Request failed" code:statusCode userInfo:info]);
        }
        
        else{
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

-(void)logRequest:(HLServiceRequest *)request response:(FDResponseInfo *)response{
    NSString *path = request.URL.path;
    if (path) {
        if (![self.loggedAPICalls containsObject:path]) {
            [self.loggedAPICalls addObject:path];
            FDMemLogger *logger = [FDMemLogger new];
            [logger addErrorInfo:@{ @"request" : request.toString, @"response" : response.toString}];
            [logger upload];
        }
    }
}

@end
