//
//  FDRanking.m
//  FreshdeskSDK
//
//  Created by kirthikas on 05/02/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FDRanking.h"
#import "FDCoreDataFetchManager.h"
#import "FDIndex.h"
#import "FDArticleContent.h"
#import "FDCoreDataCoordinator.h"

@implementation FDRanking

+(NSMutableArray *)rankTheArticleForSearchTerm:(NSString *)term withContext:(NSManagedObjectContext *)context{
    //tokenize string
    NSMutableDictionary *articleDictionary = [[NSMutableDictionary alloc] init];
    term = [term lowercaseString];
    NSArray *wordsArray = [term componentsSeparatedByString:@" "];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:MOBIHELP_DB_INDEX_ENTITY];
    NSError *fetchError;
    NSUInteger wordCount = [wordsArray count];
    for (int i=0; i < wordCount; i++) {
        NSString* searchWord =wordsArray[i];
        if (searchWord.length > 2 ) {
            searchWord = [@"*" stringByAppendingString:[searchWord stringByAppendingString:@"*"]];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"keyWord like %@",searchWord];
            [request setPredicate:predicate];
            NSArray *matchingIndices = [context executeFetchRequest:request error:&fetchError];
            NSUInteger indexCount =[matchingIndices count];
            for (int j=0; j< indexCount; j++) {
                NSInteger rank =0;
                FDIndex *index = matchingIndices[j];
                NSString *articleID = [index.articleID stringValue];
                if ([articleDictionary objectForKey:articleID]) {
                    rank = [[articleDictionary objectForKey:articleID] integerValue];
                }
                if (index.titleMatches) {
                    articleDictionary[articleID] = [NSNumber numberWithInteger:rank + 2] ;
                }
                if (index.descMatches) {
                    articleDictionary[articleID] = [NSNumber numberWithInteger:rank + 1] ;
                }
            }
        }
    }
    request = [NSFetchRequest fetchRequestWithEntityName:MOBIHELP_DB_ARTICLE_ENTITY];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title like[cd] %@",term];
    [request setPredicate:predicate];
    NSArray *matchingArticles = [context executeFetchRequest:request error:&fetchError];
    for (int i=0; i<[matchingArticles count]; i++) {
        NSInteger rank = 0;
        FDArticle *article = matchingArticles[i];
        if ([articleDictionary objectForKey:article.articleID]) {
            rank = [[articleDictionary objectForKey:article.articleID] integerValue];
        }
        articleDictionary[[article.articleID stringValue]] = [NSNumber numberWithInteger:rank + 2];
    }
    predicate = [NSPredicate predicateWithFormat:@"descriptionPlainText like[cd] %@",term];
    [request setPredicate:predicate];
    matchingArticles = [context executeFetchRequest:request error:&fetchError];
    for (int i=0; i<[matchingArticles count]; i++) {
        NSInteger rank = 0;
        FDArticle *article = matchingArticles[i];
        if ([articleDictionary objectForKey:article.articleID]) {
            rank = [[articleDictionary objectForKey:article.articleID] integerValue];
        }
        articleDictionary[[article.articleID stringValue]] = [NSNumber numberWithInteger:rank + 1];
    }
    NSArray *sortedKeys = [articleDictionary keysSortedByValueUsingComparator:
                           ^NSComparisonResult(id obj1, id obj2) {
                               return [obj2 compare:obj1];
                           }];
    NSMutableArray *articles = [[NSMutableArray alloc]init];
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    for (NSString* articleID in sortedKeys) {
        NSNumber *myNumber = [f numberFromString:articleID];
        FDArticle *article = [FDArticle getArticleWithID:myNumber inManagedObjectContext:context];
        FDArticleContent *articleContent = [[FDArticleContent alloc] initWithArticle:article];
        [articles addObject:articleContent];
    }
    return articles;
}

@end
