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

@implementation HLArticle

@dynamic articleDescription;
@dynamic articleID;
@dynamic categoryID;
@dynamic lastUpdatedTime;
@dynamic position;
@dynamic title;
@dynamic category;

+(HLArticle *)articleWithInfo:(NSDictionary *)articleInfo inManagedObjectContext:(NSManagedObjectContext *)context{
    HLArticle *article = nil;
    article = [NSEntityDescription insertNewObjectForEntityForName:HOTLINE_ARTICLE_ENTITY inManagedObjectContext:context];
    article.articleID            = [articleInfo valueForKey:@"articleId"];
    article.title                = [articleInfo valueForKey:@"title"];
    article.articleDescription   = [articleInfo valueForKey:@"content"];
    article.position             = @([[articleInfo valueForKey:@"position"]intValue]);
    return article;
}


@end
