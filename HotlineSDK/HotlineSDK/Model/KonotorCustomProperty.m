//
//  KonotorCustomProperty.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 15/02/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "KonotorCustomProperty.h"
#import "KonotorDataManager.h"
#import "HLMacros.h"

@implementation KonotorCustomProperty

@dynamic key;
@dynamic serializedData;
@dynamic uploadStatus;
@dynamic value;
@dynamic isUserProperty;

+(KonotorCustomProperty*)createNewPropertyForKey:(NSString *)key WithValue:(NSString *)value isUserProperty:(BOOL)isUserProperty{
    NSManagedObjectContext *context = [[KonotorDataManager sharedInstance]mainObjectContext];
    KonotorCustomProperty *property =  [KonotorCustomProperty getCustomPropertyWithKey:key withContext:context];
    if (property) {
        if (![value isEqualToString:property.value]) {
            property.value = value;
            property.uploadStatus = @0;
            property.isUserProperty = isUserProperty;
        }
    }else{
        property = [NSEntityDescription insertNewObjectForEntityForName:@"KonotorCustomProperty" inManagedObjectContext:context];
        property.uploadStatus = @0;
        property.key = key;
        property.value = value;
        property.isUserProperty = isUserProperty;
    }
    [[KonotorDataManager sharedInstance]save];
    return property;
}

+(KonotorCustomProperty *)getCustomPropertyWithKey:(NSString *)key withContext:(NSManagedObjectContext *)context{
    KonotorCustomProperty *property = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"KonotorCustomProperty"];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"key == %@",key];
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
    NSManagedObjectContext *context = [[KonotorDataManager sharedInstance]mainObjectContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"KonotorCustomProperty"];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"uploadStatus == NO"];
    return [context executeFetchRequest:fetchRequest error:nil];
}

@end