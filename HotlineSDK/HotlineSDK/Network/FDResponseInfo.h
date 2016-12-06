//
//  FDResponseInfo.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 27/01/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDResponseInfo : NSObject

@property (nonatomic, strong) NSURLResponse *response;

-(instancetype)initWithResponse:(NSURLResponse *)response andHTTPBody:(NSData *)data;

-(BOOL)isArray;

-(BOOL)isDict;

-(NSArray *)responseAsArray;

-(NSDictionary *)responseAsDictionary;

-(NSDictionary *)toString;

@end
