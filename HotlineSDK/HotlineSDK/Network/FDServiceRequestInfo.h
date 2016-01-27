//
//  FDServiceRequestInfo.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 27/01/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDServiceRequestInfo : NSObject

@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) id responseHTTPBody;

-(NSDictionary *)requestHTTPBody;

-(instancetype)initWithRequest:(NSURLRequest *)request andResponse:(NSURLResponse *)response;

@end