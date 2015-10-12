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
#import "HLMacros.h"

@implementation HLCategory

@dynamic categoryDescription;
@dynamic categoryID;
@dynamic icon;
@dynamic position;
@dynamic title;
@dynamic articles;
@dynamic iconURL;
@dynamic lastUpdatedTime;

+(HLCategory *)getWithID:(NSNumber *)categoryID inContext:(NSManagedObjectContext *)context{
    HLCategory *category = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_CATEGORY_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"categoryID == %@",categoryID];
    NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
    if (matches.count == 1) {
        category = matches.firstObject;
    }
    if (matches.count > 1) {
        FDLog(@"Duplicates found in Articles table !");
        category = nil;
    }
    return category;
}

+(HLCategory *)createWithInfo:(NSDictionary *)categoryInfo inContext:(NSManagedObjectContext *)context{
    HLCategory *category = [NSEntityDescription insertNewObjectForEntityForName:HOTLINE_CATEGORY_ENTITY inManagedObjectContext:context];
    return [self updateCategory:category withInfo:categoryInfo];
}

-(void)updateWithInfo:(NSDictionary *)categoryInfo{
    [HLCategory updateCategory:self withInfo:categoryInfo];
}

+(HLCategory *)updateCategory:(HLCategory *)category withInfo:(NSDictionary *)categoryInfo{
    category.categoryID = categoryInfo[@"categoryId"];
    category.title = categoryInfo[@"title"];
    category.iconURL = categoryInfo[@"icon"];
    category.position = categoryInfo[@"position"];
    category.lastUpdatedTime = [NSDate dateWithTimeIntervalSince1970:[categoryInfo[@"lastUpdatedAt"]doubleValue]];
    category.categoryDescription = categoryInfo[@"description"];

    //Prefetch images
    __block NSData *imageData = nil;
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:categoryInfo[@"icon"]]];
    });
    category.icon = imageData;
    
    //Add Articles
    NSArray *articles =  categoryInfo[@"articles"];
    for (int j=0; j<articles.count; j++) {
        NSDictionary *articleInfo = articles[j];
        HLArticle *article = [HLArticle articleWithInfo:articleInfo inManagedObjectContext:category.managedObjectContext];
        [category addArticlesObject:article];
    }
    return category;
}

@end