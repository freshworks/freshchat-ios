//
//  FDSecureStore.h
//  FreshdeskSDK
//
//  Created by Aravinth on 01/08/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#ifndef FreshdeskSDK_FDSecureStore_h
#define FreshdeskSDK_FDSecureStore_h

#import <Foundation/Foundation.h>

@interface FDSecureStore : NSObject

+(instancetype)sharedInstance;

-(void)setIntValue:(NSInteger)value forKey:(NSString *)key;
-(NSInteger)intValueForKey:(NSString *)key;

-(void)setBoolValue:(BOOL)value forKey:(NSString *)key;
-(BOOL)boolValueForKey:(NSString *)key;

-(void)setObject:(id)object forKey:(NSString *)key;
-(id)objectForKey:(NSString *)key;

//Check if an item exists
-(BOOL)checkItemWithKey:(NSString *)key;

-(void)removeObjectWithKey:(NSString *)key;
-(void)clearStoreData;

//Test
-(void)logStoreData;

@end

#endif