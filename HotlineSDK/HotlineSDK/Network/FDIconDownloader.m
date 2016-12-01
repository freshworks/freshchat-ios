//
//  IconDownloader.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 26/05/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FDIconDownloader.h"

@interface FDIconDownloader ()

@property (nonatomic, assign) dispatch_queue_t queue;


@end

@implementation FDIconDownloader

- (instancetype)init{
    self = [super init];
    if (self) {
        self.queue = dispatch_queue_create("com.freshdesk.hotline_sdk", NULL);
    }
    return self;
}

-(void)enqueue:(void (^)(void))handler{
    dispatch_async(self.queue, handler);
}

-(void)dealloc{
    if (self.queue) {
        dispatch_release(self.queue);
    }
}

@end
