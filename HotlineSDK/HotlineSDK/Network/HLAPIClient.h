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

@interface HLAPIClient : NSObject

typedef void(^HLNetworkCallback)(FDResponseInfo *responseInfo, NSError *error);

+(id)sharedInstance;

-(NSURLSessionDataTask *)request:(HLServiceRequest *)request withHandler:(HLNetworkCallback)handler;

@end


