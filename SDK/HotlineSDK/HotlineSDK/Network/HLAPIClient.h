//
//  HLAPIClient.h
//  
//
//  Created by Aravinth Chandran on 21/09/15.
//
//

#import <Foundation/Foundation.h>

@interface HLAPIClient : NSObject

typedef void(^HLNetworkCallback)(id responseObject, NSError *error);

+(id)sharedInstance;
-(NSURLSessionDataTask *)GET:(NSURLRequest *)request withHandler:(HLNetworkCallback)handler;
-(NSURLSessionDataTask *)PUT:(NSURLRequest *)request withHandler:(HLNetworkCallback)handler;

@end


