//
//  FDResponseInfo.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 27/01/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FDResponseInfo.h"

@implementation FDResponseInfo

-(instancetype)initWithResponse:(NSURLResponse *)response{
    self = [super init];
    if (self) {
        self.response = response;
    }
    return self;
}

@end