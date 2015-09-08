// FDNetworkReachabilityManager.m
// 
// Copyright (c) 2013-2014 FDNetworking (http://FDnetworking.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "FDNetworkReachabilityManager.h"

#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

NSString * const FDNetworkingReachabilityDidChangeNotification = @"com.alamofire.networking.reachability.change";
NSString * const FDNetworkingReachabilityNotificationStatusItem = @"FDNetworkingReachabilityNotificationStatusItem";

typedef void (^FDNetworkReachabilityStatusBlock)(FDNetworkReachabilityStatus status);

typedef NS_ENUM(NSUInteger, FDNetworkReachabilityAssociation) {
    FDNetworkReachabilityForAddress = 1,
    FDNetworkReachabilityForAddressPair = 2,
    FDNetworkReachabilityForName = 3,
};

NSString * FDStringFromNetworkReachabilityStatus(FDNetworkReachabilityStatus status) {
    switch (status) {
        case FDNetworkReachabilityStatusNotReachable:
            return NSLocalizedStringFromTable(@"Not Reachable", @"FDNetworking", nil);
        case FDNetworkReachabilityStatusReachableViaWWAN:
            return NSLocalizedStringFromTable(@"Reachable via WWAN", @"FDNetworking", nil);
        case FDNetworkReachabilityStatusReachableViaWiFi:
            return NSLocalizedStringFromTable(@"Reachable via WiFi", @"FDNetworking", nil);
        case FDNetworkReachabilityStatusUnknown:
        default:
            return NSLocalizedStringFromTable(@"Unknown", @"FDNetworking", nil);
    }
}

static FDNetworkReachabilityStatus FDNetworkReachabilityStatusForFlags(SCNetworkReachabilityFlags flags) {
    BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
    BOOL needsConnection = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
    BOOL canConnectionAutomatically = (((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0));
    BOOL canConnectWithoutUserInteraction = (canConnectionAutomatically && (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0);
    BOOL isNetworkReachable = (isReachable && (!needsConnection || canConnectWithoutUserInteraction));

    FDNetworkReachabilityStatus status = FDNetworkReachabilityStatusUnknown;
    if (isNetworkReachable == NO) {
        status = FDNetworkReachabilityStatusNotReachable;
    }
#if	TARGET_OS_IPHONE
    else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
        status = FDNetworkReachabilityStatusReachableViaWWAN;
    }
#endif
    else {
        status = FDNetworkReachabilityStatusReachableViaWiFi;
    }

    return status;
}

static void FDNetworkReachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void *info) {
    FDNetworkReachabilityStatus status = FDNetworkReachabilityStatusForFlags(flags);
    FDNetworkReachabilityStatusBlock block = (__bridge FDNetworkReachabilityStatusBlock)info;
    if (block) {
        block(status);
    }


    dispatch_async(dispatch_get_main_queue(), ^{
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter postNotificationName:FDNetworkingReachabilityDidChangeNotification object:nil userInfo:@{ FDNetworkingReachabilityNotificationStatusItem: @(status) }];
    });
    
}

static const void * FDNetworkReachabilityRetainCallback(const void *info) {
    return Block_copy(info);
}

static void FDNetworkReachabilityReleaseCallback(const void *info) {
    if (info) {
        Block_release(info);
    }
}

@interface FDNetworkReachabilityManager ()
@property (readwrite, nonatomic, assign) SCNetworkReachabilityRef networkReachability;
@property (readwrite, nonatomic, assign) FDNetworkReachabilityAssociation networkReachabilityAssociation;
@property (readwrite, nonatomic, assign) FDNetworkReachabilityStatus networkReachabilityStatus;
@property (readwrite, nonatomic, copy) FDNetworkReachabilityStatusBlock networkReachabilityStatusBlock;
@end

@implementation FDNetworkReachabilityManager

+ (instancetype)sharedManager {
    static FDNetworkReachabilityManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct sockaddr_in address;
        bzero(&address, sizeof(address));
        address.sin_len = sizeof(address);
        address.sin_family = AF_INET;

        _sharedManager = [self managerForAddress:&address];
    });

    return _sharedManager;
}

+ (instancetype)managerForDomain:(NSString *)domain {
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [domain UTF8String]);

    FDNetworkReachabilityManager *manager = [[self alloc] initWithReachability:reachability];
    manager.networkReachabilityAssociation = FDNetworkReachabilityForName;

    return manager;
}

+ (instancetype)managerForAddress:(const void *)address {
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)address);

    FDNetworkReachabilityManager *manager = [[self alloc] initWithReachability:reachability];
    manager.networkReachabilityAssociation = FDNetworkReachabilityForAddress;

    return manager;
}

- (instancetype)initWithReachability:(SCNetworkReachabilityRef)reachability {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.networkReachability = reachability;
    self.networkReachabilityStatus = FDNetworkReachabilityStatusUnknown;

    return self;
}

- (void)dealloc {
    [self stopMonitoring];

    if (_networkReachability) {
        CFRelease(_networkReachability);
        _networkReachability = NULL;
    }
}

#pragma mark -

- (BOOL)isReachable {
    return [self isReachableViaWWAN] || [self isReachableViaWiFi];
}

- (BOOL)isReachableViaWWAN {
    return self.networkReachabilityStatus == FDNetworkReachabilityStatusReachableViaWWAN;
}

- (BOOL)isReachableViaWiFi {
    return self.networkReachabilityStatus == FDNetworkReachabilityStatusReachableViaWiFi;
}

#pragma mark -

- (void)startMonitoring {
    [self stopMonitoring];

    if (!self.networkReachability) {
        return;
    }

    __weak __typeof(self)weakSelf = self;
    FDNetworkReachabilityStatusBlock callback = ^(FDNetworkReachabilityStatus status) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;

        strongSelf.networkReachabilityStatus = status;
        if (strongSelf.networkReachabilityStatusBlock) {
            strongSelf.networkReachabilityStatusBlock(status);
        }

    };

    SCNetworkReachabilityContext context = {0, (__bridge void *)callback, FDNetworkReachabilityRetainCallback, FDNetworkReachabilityReleaseCallback, NULL};
    SCNetworkReachabilitySetCallback(self.networkReachability, FDNetworkReachabilityCallback, &context);
    SCNetworkReachabilityScheduleWithRunLoop(self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);

    switch (self.networkReachabilityAssociation) {
        case FDNetworkReachabilityForName:
            break;
        case FDNetworkReachabilityForAddress:
        case FDNetworkReachabilityForAddressPair:
        default: {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
                SCNetworkReachabilityFlags flags;
                SCNetworkReachabilityGetFlags(self.networkReachability, &flags);
                FDNetworkReachabilityStatus status = FDNetworkReachabilityStatusForFlags(flags);
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(status);
                    
                    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
                    [notificationCenter postNotificationName:FDNetworkingReachabilityDidChangeNotification object:nil userInfo:@{ FDNetworkingReachabilityNotificationStatusItem: @(status) }];

                    
                });
            });
        }
            break;
    }
}

- (void)stopMonitoring {
    if (!self.networkReachability) {
        return;
    }

    SCNetworkReachabilityUnscheduleFromRunLoop(self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
}

#pragma mark -

- (NSString *)localizedNetworkReachabilityStatusString {
    return FDStringFromNetworkReachabilityStatus(self.networkReachabilityStatus);
}

#pragma mark -

- (void)setReachabilityStatusChangeBlock:(void (^)(FDNetworkReachabilityStatus status))block {
    self.networkReachabilityStatusBlock = block;
}

#pragma mark - NSKeyValueObserving

+ (NSSet *)keyPathsForValuesFDfectingValueForKey:(NSString *)key {
    if ([key isEqualToString:@"reachable"] || [key isEqualToString:@"reachableViaWWAN"] || [key isEqualToString:@"reachableViaWiFi"]) {
        return [NSSet setWithObject:@"networkReachabilityStatus"];
    }

    return [super keyPathsForValuesAffectingValueForKey:key];
}

@end
