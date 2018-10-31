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
#import "FCSecureStore.h"
#import "FCRemoteConfig.h"
#import "FCCoreServices.h"


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

- (NSURLSessionDataTask *)request:(FCServiceRequest *)request isIdAuthEnabled: (BOOL) isAuthEnabled withHandler:(HLNetworkCallback)handler{
    
    if( isAuthEnabled && [[FCRemoteConfig sharedInstance] isUserAuthEnabled]) {
        if([[FCJWTAuthValidator sharedInstance] canSetStateToNotProcessed]) {
            [[FCJWTAuthValidator sharedInstance] updateAuthState:TOKEN_NOT_PROCESSED];
        }
        //TODO : rename FRESHCHAT_DEFAULTS_IS_FIRST_AUTH
        if([[FCSecureStore sharedInstance] boolValueForKey:FRESHCHAT_DEFAULTS_IS_FIRST_AUTH]) {
            if ([FCStringUtil isEmptyString:[FreshchatUser sharedInstance].jwtToken]) {
                NSError *error = [NSError errorWithDomain:@"JWT_ERROR" code:1 userInfo:@{ @"Reason" : @"JWT Failed" }];
                [[FCJWTAuthValidator sharedInstance] updateAuthState:TOKEN_INVALID];
                if (handler) handler(nil, error);
                return Nil;
            }
        }
    }
    
    NSURLSessionDataTask *task = [self request:request withHandler:^(FCResponseInfo *responseInfo, NSError *error) {
        if (handler) handler(responseInfo, error ? error : nil);
    }];
    return task;
}

-(NSURLSessionDataTask *)request:(FCServiceRequest *)request withHandler:(HLNetworkCallback)handler {
    if([FCUtilities isAccountDeleted]){
        return Nil;
    }
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
        
        FCResponseInfo *responseInfo = [[FCResponseInfo alloc]initWithResponse:response andHTTPBody:data];
        
        if (statusCode >= BadRequest) {
            
            if ([[FCRemoteConfig sharedInstance] isUserAuthEnabled]) {
                if(statusCode == UnAuthorized || statusCode == TokenRequired) {
                    [[FCJWTAuthValidator sharedInstance] updateAuthState:TOKEN_INVALID];
                    if (handler) handler(responseInfo, error ? error : nil);
                }
            }
            
            if(statusCode == Gone){//For GDPR compliance
                self.FC_IS_USER_OR_ACCOUNT_DELETED = YES;
                [FCUtilities handleGDPRForResponse:responseInfo];
                if (handler) handler(responseInfo,nil);
            }
            else {
                [self logRequest:request];
                NSDictionary *info = @{ @"Status code" : [NSString stringWithFormat:@"%ld", (long)statusCode] };
                if (handler) handler(responseInfo,[NSError errorWithDomain:@"Request failed" code:statusCode userInfo:info]);
            }
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
