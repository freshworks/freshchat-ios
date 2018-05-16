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

typedef enum {
    BADREQUEST = 400,
    GONE = 410
} FCHTTPRESPONSE;

@interface HLAPIClient : NSObject

typedef void(^HLNetworkCallback)(FDResponseInfo *responseInfo, NSError *error);

+(id)sharedInstance;

-(NSURLSessionDataTask *)request:(HLServiceRequest *)request withHandler:(HLNetworkCallback)handler;

@end


