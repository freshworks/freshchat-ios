//
//  FDBreadCrumb.m
//  FreshdeskSDK
//
//  Created by balaji on 14/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDBreadCrumb.h"
#import "FDDateUtil.h"
#import "FDQueue.h"
#import "FDSecureStore.h"
#import "FDConstants.h"

@interface FDBreadCrumb ()

@property (strong, nonatomic) FDQueue *breadCrumbStore;
@property (strong, nonatomic) FDSecureStore *secureStore;

@end

@implementation FDBreadCrumb

@synthesize breadCrumbStore = _breadCrumbStore;

+ (instancetype)sharedInstance{
    static FDBreadCrumb *_sharedBreadCrumb = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedBreadCrumb = [[self alloc]init];
    });
    return _sharedBreadCrumb;
}

-(FDSecureStore *)secureStore{
    if(!_secureStore){
        _secureStore = [FDSecureStore sharedInstance];
    }
    return _secureStore;
}

-(FDQueue *)breadCrumbStore{
    if(!_breadCrumbStore){
        _breadCrumbStore = [[FDQueue alloc]initWithSize:MOBIHELP_CONSTANTS_BREADCRUMB_LIMIT];
        id existingData  = [self.secureStore objectForKey:MOBIHELP_DEFAULTS_BREAD_CRUMBS];
        if (existingData) _breadCrumbStore = existingData;
    }
    _breadCrumbStore.queueSize = MOBIHELP_CONSTANTS_BREADCRUMB_LIMIT;
    return _breadCrumbStore;
}

- (void)addCrumb:(NSString *)crumb {
    NSDictionary *newBreadCrumb = [self generateBreadCrumb:crumb];
    [self storeBreadCrumb:newBreadCrumb];
}

-(NSDictionary *)generateBreadCrumb:(NSString *)crumb{
    NSString *timeStamp         = [FDDateUtil getWebFriendlyTimeStamp];
    NSDictionary *newBreadCrumb = @{ @"time" : timeStamp , @"crumbText" : crumb };
    return newBreadCrumb;
}

-(void)storeBreadCrumb:(NSDictionary *)newBreadCrumb{
    [self.breadCrumbStore enqueue:newBreadCrumb];
    [self.secureStore setObject:self.breadCrumbStore forKey:MOBIHELP_DEFAULTS_BREAD_CRUMBS];
}

-(NSArray *)getCrumbs{
    return [self.breadCrumbStore contentsAsArray];
}

- (void)clearBreadCrumbs {
    [self.breadCrumbStore clear];
    [self.secureStore removeObjectWithKey:MOBIHELP_DEFAULTS_BREAD_CRUMBS];
}

@end