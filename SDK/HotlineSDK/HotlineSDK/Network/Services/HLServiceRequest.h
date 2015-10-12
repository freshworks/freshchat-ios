//
//  HLServiceRequest.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 10/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HLServiceRequest : NSMutableURLRequest

@property(nonatomic, strong, readonly) NSURL *baseURL;

// The string encoding used to serialize parameters. `NSUTF8StringEncoding` by default.
@property (nonatomic, assign) NSStringEncoding stringEncoding;

-(instancetype)initWithBaseURL:(NSURL *)baseURL;

-(void)setRelativePath:(NSString *)path andURLParams:(NSString *)params;

@end
