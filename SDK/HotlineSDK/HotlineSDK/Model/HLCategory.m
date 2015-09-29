//
//  HLCategory.m
//  
//
//  Created by Aravinth Chandran on 21/09/15.
//
//

#import "HLCategory.h"
#import "HLArticle.h"
#import "KonotorDataManager.h"

@implementation HLCategory

@dynamic categoryDescription;
@dynamic categoryID;
@dynamic icon;
@dynamic position;
@dynamic title;
@dynamic articles;

+(HLCategory *)categoryWithInfo:(NSDictionary *)categoryInfo inManagedObjectContext:(NSManagedObjectContext *)context{
    HLCategory *category = nil;
    category = [NSEntityDescription insertNewObjectForEntityForName:HOTLINE_CATEGORY_ENTITY inManagedObjectContext:context];
    category.title = categoryInfo[@"title"];
    category.position = @([categoryInfo[@"position"] intValue]);
    category.icon = nil;
    category.categoryDescription = categoryInfo[@"description"];
    return category;
}

@end
