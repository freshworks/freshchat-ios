//
//  FDCustomData.m
//  FreshdeskSDK
//
//  Created by balaji on 15/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDCustomData.h"
#import "FDQueue.h"
#import "FDSecureStore.h"
#import "FDConstants.h"
#import "FDMacros.h"



@interface FDCustomData ()

@property (strong, nonatomic) FDQueue *customDataStore;
@property (strong, nonatomic) FDSecureStore *secureStore;

@end

@implementation FDCustomData

#pragma mark - Initialization

+(instancetype)sharedInstance{
    static FDCustomData *_sharedCustomData = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedCustomData = [[self alloc]init];
    });
    return _sharedCustomData;
}

#pragma mark - Lazy Instantiations

-(FDQueue *)customDataStore{
    if(!_customDataStore){
        _customDataStore = [[FDQueue alloc]initWithSize:MOBIHELP_CONSTANTS_CUSTOM_DATA_LIMIT];
        id existingData  = [self.secureStore objectForKey:MOBIHELP_DEFAULTS_CUSTOM_DATA];
        if (existingData) _customDataStore = existingData;
    }
    _customDataStore.queueSize = MOBIHELP_CONSTANTS_CUSTOM_DATA_LIMIT;
    return _customDataStore;
}

-(FDSecureStore *)secureStore{
    if(!_secureStore){
        _secureStore = [FDSecureStore sharedInstance];
    }
    return _secureStore;
}

#pragma mark - Public API

-(void)addCustomDataWithKey:(NSString *)key andValue:(NSString *)value{
    [self addCustomDatawithKey:key andValue:value andSensitivity:NO];
}

-(void) addCustomDatawithKey:(NSString *)key andValue:(NSString *)value andSensitivity:(BOOL)isSensitive{
    NSDictionary *newCustomData = @{ key : value , MH_SENSITIVITY : @(isSensitive) };
    NSPredicate *removeKeyPredicate = [NSPredicate predicateWithFormat:@"%K == nil",key];
    [self.customDataStore removeWithPredicate:removeKeyPredicate];
    [self.customDataStore enqueue:newCustomData];
    [self.secureStore setObject:self.customDataStore forKey:MOBIHELP_DEFAULTS_CUSTOM_DATA];
}

-(NSDictionary *)getCustomData{
    NSMutableDictionary *allCustomData = [[NSMutableDictionary alloc]init];
    NSMutableArray * customDataArray = [self.customDataStore contentsAsArray];
    BOOL enhancedPrivacy = [[FDSecureStore sharedInstance] boolValueForKey:MOBIHELP_DEFAULTS_IS_ENHANCED_PRIVACY_ENABLED];
    if (enhancedPrivacy) {
        NSPredicate * predicate = [NSPredicate predicateWithFormat:@"%K != %@",MH_SENSITIVITY,@YES];
        NSArray *matches = [customDataArray filteredArrayUsingPredicate:predicate];
        customDataArray = [NSMutableArray arrayWithArray:matches];
        
    }
    for(NSDictionary* existingCustomData in customDataArray){
        [allCustomData addEntriesFromDictionary:existingCustomData];
    }
    [allCustomData removeObjectForKey:MH_SENSITIVITY];
    return allCustomData;
}

-(void)clearCustomData{
    [self.customDataStore clear];
    [self.secureStore removeObjectWithKey:MOBIHELP_DEFAULTS_CUSTOM_DATA];
}

@end