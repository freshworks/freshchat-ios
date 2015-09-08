//
//  FDCustomData.h
//  FreshdeskSDK
//
//  Created by balaji on 15/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDCustomData : NSObject

+ (FDCustomData *)sharedInstance;

- (void)addCustomDataWithKey:(NSString *)key andValue:(NSString *)value;
-(void) addCustomDatawithKey:(NSString *)key andValue:(NSString *)value andSensitivity:(BOOL)isSensitive;
- (NSDictionary *)getCustomData;
- (void)clearCustomData;

@end
