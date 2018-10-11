//
//  FCAPIClient.h
//  
//
//  Created by Aravinth Chandran on 21/09/15.
//
//

#import <Foundation/Foundation.h>
#import "FCAPI.h"
#import "FCResponseInfo.h"
#import "FCServiceRequest.h"

enum FCHTTPResponseCode {
    BadRequest = 400,
    Gone = 410
};

@interface FCAPIClient : NSObject

@property(nonatomic, assign) BOOL FC_IS_USER_OR_ACCOUNT_DELETED;

typedef void(^HLNetworkCallback)(FCResponseInfo *responseInfo, NSError *error);

+(id)sharedInstance;

- (NSURLSessionDataTask *)request:(FCServiceRequest *)request isIdAuthEnabled: (BOOL) isAuthEnabled withHandler:(HLNetworkCallback)handler;

@end


