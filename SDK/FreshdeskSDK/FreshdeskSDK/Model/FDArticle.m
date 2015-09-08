    //
//  Article.m
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 27/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDArticle.h"
#import "FDFolder.h"
#import "FDAPI.h"
#import "MobiHelpDatabase.h"

@implementation FDArticle

@dynamic articleDescription;
@dynamic articleID;
@dynamic position;
@dynamic title;
@dynamic folder;
@dynamic descriptionPlainText;

+(FDArticle *)articleWithInfo:(NSDictionary *)articleInfo inManagedObjectContext:(NSManagedObjectContext *)context{
    FDArticle *article = nil;
    article = [NSEntityDescription insertNewObjectForEntityForName:MOBIHELP_DB_ARTICLE_ENTITY inManagedObjectContext:context];
    article.articleID            = [articleInfo valueForKey:MOBIHELP_API_RESPONSE_ARTICLE_ID];
    article.title                = [articleInfo valueForKey:MOBIHELP_API_RESPONSE_ARTICLE_TITLE];
    article.articleDescription   = [articleInfo valueForKey:MOBIHELP_API_RESPONSE_ARTICLE_DESCRIPTION];
    article.descriptionPlainText = [articleInfo valueForKey:MOBIHELP_API_RESPONSE_ARTICLE_DESC_PLAIN_TEXT];
    article.position             = [articleInfo valueForKey:MOBIHELP_API_RESPONSE_ARTICLE_POSITION];
    return article;
}

/* Checks for the passed articleID in the database, returns a article if found one */
+(FDArticle *)getArticleWithID:(NSNumber *)articleID inManagedObjectContext:(NSManagedObjectContext *)context{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:MOBIHELP_DB_ARTICLE_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"articleID == %@",articleID];
    NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
    if ([matches count] > 1) return nil;
    return [matches firstObject];
}

@end
