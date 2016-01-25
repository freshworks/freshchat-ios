//
//  FDRanking.m
//  FreshdeskSDK
//
//  Created by kirthikas on 05/02/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FDRanking.h"
#import "HLArticle.h"
#import "FDIndex.h"
#import "KonotorDataManager.h"
#import "FDArticleContent.h"

@implementation FDRanking

/*

 Rank FAQ articles for Search term
 
 @discussion To rank the FAQ articles based on the search term entered, this method takes in two parameters.
 
 @param term The search term entered by the user.
 
 @param context The managed object context in which the fetchrequests for the search should be made, which is generally the background context.
 
 This ranking method returns article in the descending order of their rank.
 The ranking algorithm works as follows
 Random Word Match: In Article Title = 2, In Article Description = 1
 Exact Word Match : In Article Title = 2, In Article Description = 1
 1. Tokenize the search string
 2. Add article IDs with random matches and their respective ranking value to a dictionary
 3. Add article IDs with exact matches in article title and their respective ranking value to a dictionary
 4. Add article IDs with exact matches in article description and their respective ranking value to a dictionary
 5. Sort the articles in the article dictionary in descending order of their ranks
 6. Get articles for respective article IDs
 7. Return the fetched articles
 
 */


+(NSMutableArray *)rankTheArticleForSearchTerm:(NSString *)term withContext:(NSManagedObjectContext *)context{
    //tokenize string
    NSMutableDictionary *articleDictionary = [[NSMutableDictionary alloc] init];
    term = [term lowercaseString];
    NSArray *wordsArray = [term componentsSeparatedByString:@" "];
    articleDictionary = [FDRanking randomWordMatchFor:wordsArray forArticle:articleDictionary inContext:context];
    articleDictionary = [FDRanking exactWordMatchFor:term withPredicateString:@"title like[cd] %@" forArticle:articleDictionary inContext:context withRankValue:2];
    articleDictionary = [FDRanking exactWordMatchFor:term withPredicateString:@"articleDescription like[cd] %@" forArticle:articleDictionary inContext:context withRankValue:1];
    NSMutableArray *articles = [[NSMutableArray alloc]init];
    articles = [FDRanking sortArticles:articleDictionary inContext:context];
    return articles;
}

/*
 
 Finds FAQ articles which have random matches for the search term in the article title/article description
 
 @discussion To find FAQ articles which have random matches for the search term in the article title/article description and add them to article dictionary.
 
 @param wordsArray tokenized search term.
 
 @param articleDictionary a dictionary which contains articles and their rank values.
 
 @param context The managed object context in which the fetchrequests for the search should be made, which is generally the background context.
 
 Random matches for articles are calculated using the FDIndex table.
 The FDIndex table has titlematches and descmatches columns.
 Fetch indices which have matching keywords.
 Article dictionary sample
 { ARTICLE ID : RANK }
 For every article id we check if a rank already exists, if so then add points to the existing rank
 If a title match is found 2 points are added to the rank
 If a description match is found 1 point is found to the rank
 
*/
+(NSMutableDictionary *)randomWordMatchFor:(NSArray *)wordsArray forArticle:(NSMutableDictionary *)articleDictionary inContext:(NSManagedObjectContext *)context{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_INDEX_ENTITY];
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
    return articleDictionary;
}
/*
 
 Finds FAQ articles which have exact matches for the search term in the article title/article description
 
 @discussion To find FAQ articles which have exact matches for the search term in the article title/article description and add them to article dictionary.
 
 @param wordsArray tokenized search term.
 
 @param predicateString predicate with which the fetchrequest will be executed.
 
 @param articleDictionary a dictionary which contains articles and their rank values.
 
 @param context The managed object context in which the fetchrequests for the search should be made, which is generally the background context.
 
 Exact matches for articles are calculated using the HLArticle table.
 Fetch articles which have matching keywords.
 Article dictionary sample
 { ARTICLE ID : RANK }
 If a title match is found 2 points are added to the rank
 If a description match is found 1 point is found to the rank
 
*/
+(NSMutableDictionary *)exactWordMatchFor:(NSString *)term withPredicateString:(NSString *)predicateString forArticle:(NSMutableDictionary *)articleDictionary inContext:(NSManagedObjectContext *)context withRankValue:(NSUInteger)rankValue{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_ARTICLE_ENTITY];
    NSError *fetchError;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString,term];
    [request setPredicate:predicate];
    NSArray *matchingArticles = [context executeFetchRequest:request error:&fetchError];
    for (int i=0; i<[matchingArticles count]; i++) {
        NSInteger rank = 0;
        HLArticle *article = matchingArticles[i];
        if ([articleDictionary objectForKey:article.articleID]) {
            rank = [[articleDictionary objectForKey:article.articleID] integerValue];
        }
        articleDictionary[[article.articleID stringValue]] = [NSNumber numberWithInteger:rank + rankValue];
    }
    return articleDictionary;
}

/*
 
 Sort FAQ articles on the basis of their rank value
 
 @discussion To sort the FAQ articles on the basis of their rank value, in descending order.
 
 @param articleDictionary a dictionary which contains articles and their rank values.
 
 @param context The managed object context in which the fetchrequests for the search should be made, which is generally the background context.
 
 Sort the article id based on their rank values in descending order
 After the article id's are sorted, fetch the article for the corresponding article id
 Add the articles to the array
 Return the array of articles
 
*/
+(NSMutableArray *)sortArticles:(NSMutableDictionary *)articleDictionary inContext:(NSManagedObjectContext *)context{
    NSArray *sortedKeys = [articleDictionary keysSortedByValueUsingComparator:
                           ^NSComparisonResult(id obj1, id obj2) {
                               return [obj2 compare:obj1];
                           }];
    NSMutableArray *articles = [[NSMutableArray alloc]init];
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    for (NSString* articleID in sortedKeys) {
        NSNumber *myNumber = [f numberFromString:articleID];
        HLArticle *article = [HLArticle getWithID:myNumber inContext:context];
        FDArticleContent *articleContent = [[FDArticleContent alloc] initWithArticle:article];
        [articles addObject:articleContent];
    }
    return articles;
}

@end