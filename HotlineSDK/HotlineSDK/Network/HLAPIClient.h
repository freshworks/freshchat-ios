//
//  HLAPIClient.h
//  
//
//  Created by Aravinth Chandran on 21/09/15.
//
//

#import <Foundation/Foundation.h>
#import "HLAPI.h"
#import "FDServiceRequestInfo.h"

@interface HLAPIClient : NSObject

typedef void(^HLNetworkCallback)(FDServiceRequestInfo *requestInfo, NSError *error);

+(id)sharedInstance;

-(NSURLSessionDataTask *)request:(NSURLRequest *)request withHandler:(HLNetworkCallback)handler;

@end


