//
//  IconDownloader.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 26/05/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDIconDownloader : NSObject

-(void)enqueue:(void (^)(void))handler;

@end