//
//  FDServiceRequestInfo.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 27/01/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FDServiceRequestInfo.h"

@implementation FDServiceRequestInfo

-(instancetype)initWithRequest:(NSURLRequest *)request andResponse:(NSURLResponse *)response{
    self = [super init];
    if (self) {
        self.request = request;
        self.response = response;
    }
    return self;
}

-(NSDictionary *)requestHTTPBody{
    return [NSJSONSerialization JSONObjectWithData:self.request.HTTPBody options:NSJSONReadingAllowFragments error:nil];
}

@end