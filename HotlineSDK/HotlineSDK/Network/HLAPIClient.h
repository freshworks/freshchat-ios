//
//  HLAPIClient.h
//  
//
//  Created by Aravinth Chandran on 21/09/15.
//
//

#import <Foundation/Foundation.h>
#import "HLAPI.h"
#import "FDResponseInfo.h"
#import "HLServiceRequest.h"

enum FCHTTPResponseCode {
    BadRequest = 400,
    Gone = 410
};

@interface HLAPIClient : NSObject

@property(nonatomic, assign) BOOL FC_IS_USER_OR_ACCOUNT_DELETED;

typedef void(^HLNetworkCallback)(FDResponseInfo *responseInfo, NSError *error);

+(id)sharedInstance;

-(NSURLSessionDataTask *)request:(HLServiceRequest *)request withHandler:(HLNetworkCallback)handler;

@end


