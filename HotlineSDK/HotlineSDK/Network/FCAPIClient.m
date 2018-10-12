//
//  FCAPIClient.m
//  
//
//  Created by Aravinth Chandran on 21/09/15.
//
//

#import "FCAPIClient.h"
#import "FCMemLogger.h"
#import "FCUtilities.h"
#import "FCJWTUtilities.h"
#import "FCJWTAuthValidator.h"

@interface FCAPIClient ()

@property(nonatomic, strong) NSMutableArray *loggedAPICalls;
@property(nonatomic, strong) NSURLSession *session;

@end

@implementation FCAPIClient

+(id)sharedInstance{
    static FCAPIClient *sharedInstance = nil;
    static dispatch_once_t oncetoken;
    dispatch_once(&oncetoken,^{
        sharedInstance = [[FCAPIClient alloc]init];
    });
    return sharedInstance;
}

-(instancetype)init{
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        self.session = [NSURLSession sessionWithConfiguration:configuration];
        self.loggedAPICalls = [[NSMutableArray alloc]init];
        self.FC_IS_USER_OR_ACCOUNT_DELETED = NO;
    }
    return self;
}

////method has to be wrirren with validator
//- (void) validateStateForUserJWTWithCompletionHandler : (void(^)(enum API_STATES))handler{
//    
//}

- (NSURLSessionDataTask *)request:(FCServiceRequest *)request isIdAuthEnabled: (BOOL) isAuthEnabled withHandler:(HLNetworkCallback)handler{
    if([FCUtilities isAccountDeleted]){
        return Nil;
    }
    if (isAuthEnabled && [FCJWTUtilities isUserAuthEnabled] && [FCStringUtil isEmptyString:[FreshchatUser sharedInstance].jwtToken]){
        
        [[FCJWTAuthValidator sharedInstance] updateAuthState:VERIFICATION_UNDER_PROGRESS];

        NSError *error = [NSError errorWithDomain:@"JWT_ERROR" code:1 userInfo:@{ @"Reason" : @"JWT Failed" }];
        if (handler) handler(nil, error);
        return Nil;
    }
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
        
        FCResponseInfo *responseInfo = [[FCResponseInfo alloc]initWithResponse:response andHTTPBody:data];
        if (statusCode >= BadRequest) {
            if(statusCode == Gone){//For GDPR compliance
                self.FC_IS_USER_OR_ACCOUNT_DELETED = YES;
                [FCUtilities handleGDPRForResponse:responseInfo];
                if (handler) handler(responseInfo,nil);
            }
            else{
                [self logRequest:request];
                NSDictionary *info = @{ @"Status code" : [NSString stringWithFormat:@"%ld", (long)statusCode] };
                if (handler) handler(responseInfo,[NSError errorWithDomain:@"Request failed" code:statusCode userInfo:info]);
            }
        }
        else if (statusCode == UnAuthorized) {
            //Unauthorized state
            [[FCJWTAuthValidator sharedInstance] updateAuthState:TOKEN_VERIFICATION_FAILED];
        }
        else{
            if (handler) handler(responseInfo, error ? error : nil);
        }
        
    }];
    [task resume];
    return task;
}

-(void)logRequest:(FCServiceRequest *)request {
    NSString *path = request.URL.path;
    if (path) {
        if (![self.loggedAPICalls containsObject:path]) {
            [self.loggedAPICalls addObject:path];
            FCMemLogger *logger = [FCMemLogger new];
            [logger addErrorInfo:@{ @"request" : request.toString}];
            [logger upload];
        }
    }
}

@end
