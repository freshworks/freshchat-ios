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
@dynamic iconURL;
@dynamic lastUpdatedTime;

+(HLCategory *)categoryWithInfo:(NSDictionary *)categoryInfo inManagedObjectContext:(NSManagedObjectContext *)context{
    HLCategory *category = nil;
    category = [NSEntityDescription insertNewObjectForEntityForName:HOTLINE_CATEGORY_ENTITY inManagedObjectContext:context];
    category.categoryID = categoryInfo[@"categoryId"];
    category.title = categoryInfo[@"title"];
    category.iconURL = categoryInfo[@"icon"];
    category.position = categoryInfo[@"position"];
    category.icon = nil;
    category.lastUpdatedTime = [NSDate dateWithTimeIntervalSince1970:[categoryInfo[@"lastUpdatedAt"]doubleValue]];
    category.categoryDescription = categoryInfo[@"description"];
    return category;
}

@end
