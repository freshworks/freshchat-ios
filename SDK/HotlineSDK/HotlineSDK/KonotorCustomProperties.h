//
//  KonotorCustomProperties.h
//  Konotor
//
//  Created by Vignesh G on 08/10/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface KonotorCustomProperty : NSManagedObject

@property (nonatomic, retain) NSString * key;
@property (nonatomic, retain) NSString * value;
@property (nonatomic,retain) NSNumber *uploadStatus;
@property (nonatomic, retain) NSData *serializedData;

+(KonotorCustomProperty*) CreateNewPropertyForKey:(NSString *)key WithValue:(NSString *)value;
+(void) UploadAllUnuploadedProperties;

@end
