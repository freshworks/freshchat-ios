//
//  HLArticle.m
//  
//
//  Created by Aravinth Chandran on 21/09/15.
//
//

#import "FCArticles.h"
#import "FCCategories.h"
#import "FCDataManager.h"
#import "FCMacros.h"

@implementation FCArticles

@dynamic articleDescription;
@dynamic articleID;
@dynamic categoryID;
@dynamic lastUpdatedTime;
@dynamic position;
@dynamic title;
@dynamic category;
@dynamic articleAlias;
@dynamic categoryAlias;

+(FCArticles *)getWithID:(NSNumber *)articleID inContext:(NSManagedObjectContext *)context{
    FCArticles *article = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_ARTICLES_ENTITY];
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

+(FCArticles *)createWithInfo:(NSDictionary *)articleInfo inContext:(NSManagedObjectContext *)context{
    FCArticles *article = [NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_ARTICLES_ENTITY inManagedObjectContext:context];
    return [self updateArticle:article withInfo:articleInfo];
}

-(void)updateWithInfo:(NSDictionary *)articleInfo{
    [FCArticles updateArticle:self withInfo:articleInfo];
}

+(FCArticles *)updateArticle:(FCArticles *)article withInfo:(NSDictionary *)articleInfo{
    article.categoryID           = [articleInfo valueForKey:@"categoryId"];
    article.articleID            = [articleInfo valueForKey:@"articleId"];
    article.title                = [articleInfo valueForKey:@"title"];
    article.articleDescription   = [articleInfo valueForKey:@"content"];
    article.position             = @([[articleInfo valueForKey:@"position"]intValue]);
    article.articleAlias         = [articleInfo valueForKey:@"articleAlias"];
    article.categoryAlias        = [articleInfo valueForKey:@"categoryAlias"];
    return article;
}

@end
