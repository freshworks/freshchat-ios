//
//  FDReachabilityManager.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 07/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDReachabilityManager : NSObject

-(instancetype)initWithDomain:(NSString *)domain;
-(void)start;

@end