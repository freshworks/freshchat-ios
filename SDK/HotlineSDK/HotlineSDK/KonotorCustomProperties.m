//
//  KonotorCustomProperties.m
//  Konotor
//
//  Created by Vignesh G on 08/10/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import "KonotorCustomProperties.h"
#import "KonotorDataManager.h"
#import "WebServices.h"

@implementation KonotorCustomProperty

@dynamic key;
@dynamic value;
@dynamic serializedData,uploadStatus;

+(KonotorCustomProperty*) CreateNewPropertyForKey:(NSString *)key WithValue:(NSString *)value
{
    
    

    KonotorCustomProperty *newProperty = (KonotorCustomProperty *)[NSEntityDescription insertNewObjectForEntityForName:@"KonotorCustomProperty" inManagedObjectContext:[[KonotorDataManager sharedInstance]mainObjectContext]];
    newProperty.key = key;
    newProperty.value = value;
    [[KonotorDataManager sharedInstance]save];

    return newProperty;

}

+(KonotorCustomProperty *) FindPropertyWithKey:(NSString *) key
{
    NSError *pError;
    NSManagedObjectContext *context = [[KonotorDataManager sharedInstance]mainObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"KonotorCustomProperty" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    [request setEntity:entityDescription];
    
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"uploadStatus == 0"];
    
    [request setPredicate:predicate];
    ////NSLog(@"%@",[predicate description]);
    
    NSArray *array = [context executeFetchRequest:request error:&pError];
    
    if(!array)
        return nil;
    
    if([array count]==0)
        return nil;
    
    return nil;
    
}


+(void) UploadAllUnuploadedProperties
{
    NSError *pError;
    NSManagedObjectContext *context = [[KonotorDataManager sharedInstance]mainObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"KonotorCustomProperty" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    [request setEntity:entityDescription];
    
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"uploadStatus == 0"];
    
    [request setPredicate:predicate];
    ////NSLog(@"%@",[predicate description]);
    
    NSArray *array = [context executeFetchRequest:request error:&pError];
    
    if(!array)
        return;
    
    if([array count]==0)
        return ;
    
    
    else
    {
        for(int i=0;i<[array count];i++)
        {
            KonotorCustomProperty *property = [array objectAtIndex:i];
            if(property)
            {
                NSDictionary *dict = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:property.serializedData];
                

                [KonotorWebServices UpdateUserPropertiesWithDictionary:dict withProperty:property];
            }
        }
    }
    
    
}



@end
