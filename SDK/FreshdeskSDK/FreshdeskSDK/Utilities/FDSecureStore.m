//
//  FDSecureStore.m
//  FreshdeskSDK
//
//  Created by Aravinth on 01/08/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDSecureStore.h"
#import "FDKeyChainStore.h"
#import "FDDeviceInfo.h"
#import "FDUtilities.h"
#import "FDMacros.h"

#define MOBIHELP_SERVICE_NAME @"COM_FRESHDESK_MOBIHELP_IOS_%@"

@interface FDSecureStore ()

@property (strong, nonatomic) FDKeyChainStore  *secureStore;

@end

@implementation FDSecureStore

#pragma mark - Shared Manager

+(instancetype)sharedInstance{
    static FDSecureStore *sharedFDSecureStore = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedFDSecureStore = [[self alloc]init];
    });
    return sharedFDSecureStore;
}

#pragma mark - Lazy Instantiation

-(FDKeyChainStore *)secureStore{
    if(!_secureStore){
        NSString *serviceName = [NSString stringWithFormat:MOBIHELP_SERVICE_NAME,[FDDeviceInfo appIdentifier]];
        _secureStore = [FDKeyChainStore keyChainStoreWithService:serviceName];
        [self prepareSecureStore];
    }
    return _secureStore;
}

-(void)prepareSecureStore{
    if ([FDUtilities isFirstLaunch]){
        [self.secureStore removeAllItems];
    }
}

-(void)setIntValue:(NSInteger)value forKey:(NSString *)key{
    NSNumber *number = [NSNumber numberWithInteger:value];
    [self setObject:number forKey:key];
}

-(NSInteger)intValueForKey:(NSString *)key{
    return [[self objectForKey:key]integerValue];
}

-(void)setBoolValue:(BOOL)value forKey:(NSString *)key{
    NSNumber *boolValue = [NSNumber numberWithBool:value];
    [self setObject:boolValue forKey:key];
}

-(BOOL)boolValueForKey:(NSString *)key{
    return [[self objectForKey:key]boolValue];
}

-(void)setObject:(id)object forKey:(NSString *)key{
    @synchronized(self) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
        [self.secureStore setData:data forKey:key];
    }
}

-(id)objectForKey:(NSString *)key{
    NSData *data = [self.secureStore dataForKey:key];
    return (data) ? [NSKeyedUnarchiver unarchiveObjectWithData:data] : NULL;
}

-(void)removeObjectWithKey:(NSString *)key{
    @synchronized(self) {
        [self.secureStore removeItemForKey:key];
    }
}

-(BOOL)checkItemWithKey:(NSString *)key{
    return [self objectForKey:key] ? YES : NO;
}

-(void)logStoreData{
    FDLog(@"Secure Store Contents %@",self.secureStore);
}

-(void)clearStoreData{
    [self.secureStore removeAllItems];
}

@end