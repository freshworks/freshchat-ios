//
//  KonotorCustomProperty.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 15/02/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FCUserProperties.h"
#import "FCDataManager.h"
#import "FCMacros.h"

@implementation FCUserProperties

@dynamic key;
@dynamic serializedData;
@dynamic uploadStatus;
@dynamic value;
@dynamic isUserProperty;

+(FCUserProperties*)createNewPropertyForKey:(NSString *)key WithValue:(NSString *)value isUserProperty:(BOOL)isUserProperty{
    NSManagedObjectContext *context = [[FCDataManager sharedInstance]mainObjectContext];
    FCUserProperties *property =  [FCUserProperties getCustomPropertyWithKey:key andUserProperty:isUserProperty withContext:context];
    if (property) {
        if ([value isEqualToString:property.value]) {
            return property;
        }
    }else{
        property = [NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_USER_PROPERTIES_ENTITY inManagedObjectContext:context];
        property.key = key;
    }
    property.uploadStatus = @0;
    property.value = value;
    property.isUserProperty = isUserProperty;

    //TODO : Too many redundant saves .. Needs refactor - Rex
    [[FCDataManager sharedInstance]save];
    return property;
}


// (Key + userProperty) is unique
+(FCUserProperties *)getCustomPropertyWithKey:(NSString *)key andUserProperty:(BOOL)userProperty withContext:(NSManagedObjectContext *)context{
    FCUserProperties *property = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_USER_PROPERTIES_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"key == %@ && isUserProperty == %@",key,[NSNumber numberWithBool:userProperty]];
    NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
    if (matches.count == 1) {
        property = matches.firstObject;
    }
    if (matches.count > 1) {
        property = nil;
        FDLog(@"Attention! Duplicates found in Properties table !");
    }
    return property;
}

+(NSArray *)getUnuploadedProperties{
    NSManagedObjectContext *context = [[FCDataManager sharedInstance]mainObjectContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_USER_PROPERTIES_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"uploadStatus == NO"];
    return [context executeFetchRequest:fetchRequest error:nil];
}

@end
