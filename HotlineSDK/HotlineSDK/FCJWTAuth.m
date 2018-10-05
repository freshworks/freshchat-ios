//
//  FCJWTAuth.m
//  FreshchatSDK
//
//  Created by Harish Kumar on 05/10/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import "FCJWTAuth.h"

@implementation FCJWTAuth


+ (instancetype)sharedInstance{
    static FCJWTAuth *auth = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        auth = [[self alloc] init];
    });
    return auth;
}

-(instancetype)initWithJWTTokenStr:(NSString *) token {
    self = [super init];
    if (self) {
        
        self.state = [self getJWTStateForToken:token];
    }
    return self;
}

- (enum JWTState) getJWTStateForToken : (NSString *) token {
    
    return Active;
}

@end
