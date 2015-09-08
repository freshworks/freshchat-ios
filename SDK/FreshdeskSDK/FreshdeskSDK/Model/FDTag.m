//
//  FDTag.m
//
//
//  Created by kirthikas on 28/05/15.
//
//

#import "FDTag.h"
#import "MobiHelpDatabase.h"
#define MOBIHELP_API_RESPONSE_TAG_NAME @"name"

@implementation FDTag

@dynamic tagName;
@dynamic itemID;
@dynamic itemType;

/* returns a new tag if it is not already stored in the database */
+(FDTag *)tagForItem:(NSString *)itemType WithInfo:(NSDictionary *)tagInfo anditemID:(NSNumber *)itemID inManagedObjectContext:(NSManagedObjectContext *)context{
    FDTag *newTag         = [NSEntityDescription insertNewObjectForEntityForName:MOBIHELP_DB_TAG_ENTITY inManagedObjectContext:context];
    newTag.itemID         = itemID;
    newTag.itemType       = itemType;
    newTag.tagName        = [[tagInfo valueForKeyPath:MOBIHELP_API_RESPONSE_TAG_NAME]lowercaseString];
    return newTag;
}

@end
