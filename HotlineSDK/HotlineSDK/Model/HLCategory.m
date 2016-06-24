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
#import "HLArticleTagManager.h"

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
        category = nil;
        FDLog(@"Duplicates found in Category table !");
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
    NSManagedObjectContext *context = category.managedObjectContext;
    category.categoryID = categoryInfo[@"categoryId"];
    category.title = categoryInfo[@"title"];
    category.iconURL = categoryInfo[@"icon"];
    category.position = categoryInfo[@"position"];
    category.lastUpdatedTime = [NSDate dateWithTimeIntervalSince1970:[categoryInfo[@"lastUpdatedAt"]doubleValue]];
    category.categoryDescription = categoryInfo[@"description"];

    //Prefetch category icon
    __block NSData *imageData = nil;
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:categoryInfo[@"icon"]]];
    });
    category.icon = imageData;
    
    HLArticleTagManager *tagManager = [HLArticleTagManager sharedInstance];
    
    //Update article if exist or create a new one
    NSArray *articles =  categoryInfo[@"articles"];
    for (int j=0; j<articles.count; j++) {
        NSDictionary *articleInfo = articles[j];
        NSNumber *articleId = articleInfo[@"articleId"];
        HLArticle *article = [HLArticle getWithID:articleId inContext:context];
        BOOL isArticleEnabled = [articleInfo[@"enabled"]boolValue];
        BOOL isIOSPlatformAvail = [articleInfo[@"platforms"] containsObject:@"ios"];
        NSArray *tags = articleInfo[@"tags"];
        if (isArticleEnabled && isIOSPlatformAvail) {
            if (article) {
                [article updateWithInfo:articleInfo];
            }else{
                article = [HLArticle createWithInfo:articleInfo inContext:context];
                [category addArticlesObject:article];
            }
            if(tags){
                [tagManager removeTagsForArticleId:articleId];
                for(NSString *tagName in tags){
                    [tagManager addTag:tagName forArticleId:articleId];
                }
            }
        }else{
            if (article){
                FDLog(@"Deleting article with title : %@ with ID : %@ because its disabled !",article.title, article.articleID);
                [context deleteObject:article];
            }
            else {
               FDLog(@"Skipping article with title : %@ with ID : %@ because its disabled !",articleInfo[@"title"], articleInfo[@"articleId"]);
            }
            if(tags){
               [tagManager removeTagsForArticleId:articleId];
            }
        }
    }
    [tagManager save];
    return category;
}

@end