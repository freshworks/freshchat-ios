//
//  HLArticle.m
//  
//
//  Created by Aravinth Chandran on 21/09/15.
//
//

#import "HLArticle.h"
#import "HLCategory.h"
#import "KonotorDataManager.h"
#import "HLMacros.h"

@implementation HLArticle

@dynamic articleDescription;
@dynamic articleID;
@dynamic categoryID;
@dynamic lastUpdatedTime;
@dynamic position;
@dynamic title;
@dynamic category;

+(HLArticle *)getWithID:(NSNumber *)articleID inContext:(NSManagedObjectContext *)context{
    HLArticle *article = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_ARTICLE_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"articleID == %@",articleID];
    NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
    if (matches.count == 1) {
        article = matches.firstObject;
    }
    if (matches.count > 1) {
        article = nil;
        FDLog(@"Duplicates found in Articles table !");
    }
    return article;
}

+(HLArticle *)createWithInfo:(NSDictionary *)articleInfo inContext:(NSManagedObjectContext *)context{
    HLArticle *article = [NSEntityDescription insertNewObjectForEntityForName:HOTLINE_ARTICLE_ENTITY inManagedObjectContext:context];
    return [self updateArticle:article withInfo:articleInfo];
}

-(void)updateWithInfo:(NSDictionary *)articleInfo{
    [HLArticle updateArticle:self withInfo:articleInfo];
}

+(HLArticle *)updateArticle:(HLArticle *)article withInfo:(NSDictionary *)articleInfo{
    article.categoryID           = [articleInfo valueForKey:@"categoryId"];
    article.articleID            = [articleInfo valueForKey:@"articleId"];
    article.title                = [articleInfo valueForKey:@"title"];
    article.articleDescription   = [articleInfo valueForKey:@"content"];
    article.position             = @([[articleInfo valueForKey:@"position"]intValue]);
    return article;
}

@end