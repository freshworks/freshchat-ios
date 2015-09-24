//
//  HLArticle.m
//  
//
//  Created by Aravinth Chandran on 21/09/15.
//
//

#import "HLArticle.h"
#import "HLCategory.h"


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
    article = [NSEntityDescription insertNewObjectForEntityForName:@"HLArticle" inManagedObjectContext:context];
    article.articleID            = [articleInfo valueForKey:@"article_id"];
    article.title                = [articleInfo valueForKey:@"title"];
    article.articleDescription   = [articleInfo valueForKey:@"description_html"];
    article.position             = @([[articleInfo valueForKey:@"position"]intValue]);
    return article;
}


@end
