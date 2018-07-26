//
//  KonotorCustomProperty.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 15/02/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface FCUserProperties : NSManagedObject

@property (nullable, nonatomic, retain) NSString *key;
@property (nullable, nonatomic, retain) NSData *serializedData;
@property (nullable, nonatomic, retain) NSNumber *uploadStatus;
@property (nullable, nonatomic, retain) NSString *value;
@property (nonatomic) BOOL isUserProperty;


+(FCUserProperties*)createNewPropertyForKey:(NSString *)key WithValue:(NSString *)value isUserProperty:(BOOL)isUserProperty;
+(NSArray *)getUnuploadedProperties;

@end

NS_ASSUME_NONNULL_END
