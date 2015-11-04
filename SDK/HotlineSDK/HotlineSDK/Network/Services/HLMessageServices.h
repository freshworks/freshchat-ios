//
//  HLMessageServices.h
//  HotlineSDK
//
//  Created by user on 03/11/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HLMessageServices : NSObject

-(NSURLSessionDataTask *)fetchAllChannels;
-(void)importChannels:(NSDictionary *)responseObject;


@end
